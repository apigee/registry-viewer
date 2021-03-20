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
import 'package:grpc/grpc.dart' as grpc;
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;
import 'package:yaml/yaml.dart';

final projectDescription = "APIs from a variety of sources";
final projectDisplayName = "Motley APIs";
final projectName = "projects/motley";
final source = "googleapis";

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  await client.ensureProjectExists(rpc.Project()
    ..name = projectName
    ..displayName = projectDisplayName
    ..description = projectDescription);
  await channel.shutdown();

  // This assumes the googleapis repo is checked out in ~/Desktop/googleapis
  String root = (Platform.environment['HOME'] ?? "") + '/Desktop/googleapis';

  // API versions are in directories with names ending with this pattern.
  RegExp versionDirectoryPattern = new RegExp(r"/(v(\d+)((alpha|beta)\d+)?)$");
  final Queue<rpc.Task> tasks = Queue();
  await Future.forEach(Directory(root).listSync(recursive: true),
      (entity) async {
    if (entity is Directory) {
      final match = versionDirectoryPattern.firstMatch(entity.path);
      if ((match != null) && (match.group(1) != null)) {
        tasks.add(ImportGoogleApiTask(root, entity, match.group(1)));
      }
    }
  });
  await rpc.TaskProcessor(tasks, 64).run();
}

class ImportGoogleApiTask implements rpc.Task {
  final String root;
  final Directory entity;
  final String versionId;
  ImportGoogleApiTask(this.root, this.entity, this.versionId);

  String name() => entity.path + " " + versionId;

  void run(rpc.RegistryClient client) async {
    await client.importProtobufApi(root, entity, versionId);
  }
}

extension GoogleApiImporter on rpc.RegistryClient {
  void importProtobufApi(String root, Directory dir, String versionId) async {
    // only import APIs with service yaml that specifies their title and name
    RegExp yamlPattern = new RegExp(r"\.yaml$");
    await Future.forEach(dir.listSync(recursive: false), (entity) async {
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
