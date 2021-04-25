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
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;
import 'package:yaml/yaml.dart';

final source = "openapi_directory";

final maxDescriptionLength = 140;

void main(List<String> args) {
  CommandRunner("import", "Import specs.")
    ..addCommand(ImportOpenAPIDirectoryCommand())
    ..run(args);
}

class ImportOpenAPIDirectoryCommand extends Command {
  final name = "import";
  final description = "Import specs from the OpenAPI Directory.";

  ImportOpenAPIDirectoryCommand() {
    this.argParser
      ..addOption(
        'project_id',
        help: "Project id for imports.",
        valueHelp: "PROJECT_ID",
      )
      ..addOption(
        'path',
        help: "Path to a directory containing OpenAPI descriptions.",
        valueHelp: "PATH",
      );
  }

  void run() async {
    if (argResults['project_id'] == null) {
      throw UsageException("Please specify --project_id", this.argParser.usage);
    }
    if (argResults['path'] == null) {
      throw UsageException("Please specify --path", this.argParser.usage);
    }
    final channel = rpc.createClientChannel();
    final client = rpc.RegistryClient(channel, options: rpc.callOptions());

    final projectName = "projects/" + argResults['project_id'];
    final root = argResults['path'];

    final exists = await client.projectExists(projectName);
    await channel.shutdown();
    if (!exists) {
      throw UsageException("$projectName does not exist", this.argParser.usage);
    }

    final Queue<rpc.Task> tasks = Queue();

    // API specs are in files named "swagger.yaml" or "openapi.yaml".
    RegExp apiSpecPattern = new RegExp(r"/(swagger|openapi).yaml$");
    var paths = Directory(root).listSync(recursive: true);
    paths.sort((a, b) => a.path.compareTo(b.path));
    await Future.forEach(paths, (entity) async {
      if (entity is File) {
        if (apiSpecPattern.hasMatch(entity.path)) {
          tasks.add(ImportOpenAPIDirectoryTask(root, entity.path, projectName));
        }
      }
    });

    await rpc.TaskProcessor(tasks, 64).run();
  }
}

class ImportOpenAPIDirectoryTask implements rpc.Task {
  final String root;
  final String path;
  final String projectName;

  ImportOpenAPIDirectoryTask(this.root, this.path, this.projectName);

  String name() => path;

  void run(rpc.RegistryClient client) async {
    var name = path.substring(root.length + 1);

    var parts = name.split("/");
    var apiParts = parts.sublist(0, parts.length - 2);
    var owner = filterOwner(apiParts[0]);
    var apiId;
    if (apiParts.length == 1) {
      apiId = owner;
    } else {
      apiId = owner + "-" + apiParts.sublist(1).join("-");
    }
    apiId = apiId.toLowerCase();
    var versionId = parts[parts.length - 2];
    var specId = parts.last;

    try {
      String contents = await File(path).readAsString();
      var doc = loadYaml(contents);

      // compute mime type from internal format string
      var mimeType;
      var swagger = doc["swagger"];
      if (swagger != null) {
        mimeType = "application/x.openapi+gzip;version=" + swagger;
      }
      var openapi = doc["openapi"];
      if (openapi != null) {
        mimeType = "application/x.openapi+gzip;version=" + openapi;
      }
      var info = doc["info"];
      var apiTitle = info["title"] ?? "";
      if (owner == "google") {
        apiTitle = GoogleApis.titleForTitle(apiTitle);
      }
      var description = info["description"] ?? "";
      if (description.length > maxDescriptionLength) {
        description = description.substring(0, maxDescriptionLength) + "...";
      }

      final apiName = projectName + "/apis/" + apiId;
      var api = rpc.Api()
        ..name = apiName
        ..displayName = apiTitle
        ..description = description;
      api.labels["created_from"] = source;
      api.labels["owner"] = owner;
      await client.ensureApiExists(api);

      final versionName = apiName + "/versions/" + versionId;
      var version = rpc.ApiVersion()
        ..name = versionName
        ..displayName = versionId;
      version.labels["created_from"] = source;
      await client.ensureApiVersionExists(version);

      final specName = versionName + "/specs/" + specId;
      if (!await client.apiSpecExists(specName)) {
        var apiSpec = rpc.ApiSpec()
          ..filename = specId
          ..contents = GZipEncoder().encode(Utf8Encoder().convert(contents))
          ..mimeType = mimeType;
        apiSpec.labels["created_from"] = source;
        var request = rpc.CreateApiSpecRequest()
          ..parent = versionName
          ..apiSpecId = specId
          ..apiSpec = apiSpec;
        await client.createApiSpec(request);
      }
    } catch (error) {
      print("$error");
    }
  }

  String filterOwner(String owner) {
    return owner.toLowerCase();
  }
}
