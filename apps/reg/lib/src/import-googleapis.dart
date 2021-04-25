// Copyright 2021 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;
import 'package:yaml/yaml.dart';

final source = "googleapis";

class ImportGoogleAPIsCommand extends Command {
  final name = "googleapis";
  final description = "Import specs from the GoogleAPIs repository.";

  ImportGoogleAPIsCommand() {
    this.argParser
      ..addOption(
        'project',
        help: "Project for imports.",
        valueHelp: "PROJECT",
      )
      ..addOption(
        'path',
        help: "Path to a directory containing the GoogleAPIs repository.",
        valueHelp: "PATH",
      );
  }

  void run() async {
    if (argResults['project'] == null) {
      throw UsageException("Please specify --project", this.argParser.usage);
    }
    if (argResults['path'] == null) {
      throw UsageException("Please specify --path", this.argParser.usage);
    }
    final channel = rpc.createClientChannel();
    final client = rpc.RegistryClient(channel, options: rpc.callOptions());

    final projectName = argResults['project'];

    final exists = await client.projectExists(projectName);
    await channel.shutdown();
    if (!exists) {
      throw UsageException("$projectName does not exist", this.argParser.usage);
    }

    String root = argResults['path'];

    // API versions are in directories with names ending with this pattern.
    RegExp versionDirectoryPattern =
        new RegExp(r"/(v(\d+)((alpha|beta)\d+)?)$");
    final Queue<rpc.Task> tasks = Queue();
    await Future.forEach(Directory(root).listSync(recursive: true),
        (entity) async {
      if (entity is Directory) {
        final match = versionDirectoryPattern.firstMatch(entity.path);
        if ((match != null) && (match.group(1) != null)) {
          tasks.add(
              ImportGoogleApiTask(root, projectName, entity, match.group(1)));
        }
      }
    });
    await rpc.TaskProcessor(tasks, 64).run();
  }
}

class ImportGoogleApiTask implements rpc.Task {
  final String root;
  final String projectName;
  final Directory entity;
  final String versionId;
  ImportGoogleApiTask(this.root, this.projectName, this.entity, this.versionId);

  String name() => entity.path + " " + versionId;

  void run(rpc.RegistryClient client) async {
    await client.importProtobufApi(root, projectName, entity, versionId);
  }
}

extension GoogleApiImporter on rpc.RegistryClient {
  void importProtobufApi(
      String root, String projectName, Directory dir, String versionId) async {
    // only import APIs with service yaml that specifies their title and name
    RegExp yamlPattern = new RegExp(r"\.yaml$");
    await Future.forEach(dir.listSync(recursive: true), (entity) async {
      if ((entity is File) &&
          yamlPattern.hasMatch(entity.path) &&
          !entity.path.contains("gapic")) {
        String contents = await File(entity.path).readAsString();
        var doc = loadYaml(contents);
        if ((doc["type"] == "google.api.Service") &&
            (doc["title"] != null) &&
            (doc["name"] != null)) {
          var apiTitle = GoogleApis.titleForTitle(doc["title"]);

          var apiId = doc["name"];
          String suffix = ".googleapis.com";
          if (apiId.endsWith(suffix)) {
            apiId = apiId.substring(0, apiId.length - suffix.length);
            apiId = "googleapis.com-" + apiId;
          }
          print("apiId: " + apiId);

          var path = dir.path.substring(root.length + 1);
          var specId = path.replaceAll("/", "-") + ".zip";
          print("specId: " + specId);

          String description = "";
          var documentation = doc["documentation"];
          if (documentation != null) {
            var summary = documentation["summary"];
            if (summary != null) {
              description = summary as String;
              description = description.replaceAll("\n", " ");
            }
          }
          final apiName = projectName + "/apis/" + apiId;
          var api = rpc.Api()
            ..name = apiName
            ..displayName = apiTitle
            ..description = description;
          api.labels["created_from"] = source;
          api.labels["owner"] = "googleapis.com";
          await this.ensureApiExists(api);

          final versionName = apiName + "/versions/" + versionId;
          var version = rpc.ApiVersion()
            ..name = versionName
            ..displayName = versionId;
          version.labels["created_from"] = source;
          await this.ensureApiVersionExists(version);

          final specName = versionName + "/specs/" + specId;
          if (!await this.apiSpecExists(specName)) {
            var archive = Archive();
            await Future.forEach(dir.listSync(recursive: false), (file) async {
              if (file is File) {
                var name = file.path.substring(root.length + 1);
                List<int> content = await File(file.path).readAsBytes();
                archive.addFile(ArchiveFile(name, content.length, content));
              }
            });
            var apiSpec = rpc.ApiSpec()
              ..filename = specId
              ..contents = ZipEncoder().encode(archive)
              ..sourceUri = ""
              ..mimeType = "application/x.protobuf+zip";
            apiSpec.labels["created_from"] = source;
            var request = rpc.CreateApiSpecRequest()
              ..parent = versionName
              ..apiSpecId = specId
              ..apiSpec = apiSpec;
            try {
              await this.createApiSpec(request, options: rpc.callOptions());
            } on grpc.GrpcError catch (error) {
              if (error.code != grpc.StatusCode.alreadyExists) {
                rethrow;
              }
            }
          }
        }
      }
    });
  }
}
