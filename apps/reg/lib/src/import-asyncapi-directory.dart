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
import 'package:args/command_runner.dart';
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;
import 'package:yaml/yaml.dart';

final source = "asyncapi_directory";

final maxDescriptionLength = 140;

String projectName;

class ImportAsyncAPIDirectoryCommand extends Command {
  final name = "asyncapi-directory";
  final description = "Import specs from an AsyncAPI Directory.";

  ImportAsyncAPIDirectoryCommand() {
    this.argParser
      ..addOption(
        'project_id',
        help: "Project id for imports.",
        valueHelp: "PROJECT_ID",
      )
      ..addOption(
        'path',
        help: "Path to a directory containing AsyncAPI descriptions.",
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

    projectName = "projects/" + argResults['project_id'];
    final root = argResults['path'];

    final exists = await client.projectExists(projectName);
    await channel.shutdown();
    if (!exists) {
      throw UsageException("$projectName does not exist", this.argParser.usage);
    }

    // API specs are in files named "asyncapi.yaml".
    RegExp apiSpecPattern = new RegExp(r"/asyncapi.yaml$");
    var paths = Directory(root).listSync(recursive: true);
    paths.sort((a, b) => a.path.compareTo(b.path));
    await Future.forEach(paths, (entity) async {
      if (entity is File) {
        if (apiSpecPattern.hasMatch(entity.path)) {
          await client.importAsyncAPI(root, entity.path);
        }
      }
    });

    await channel.shutdown();
  }
}

extension AsyncAPIImporter on rpc.RegistryClient {
  void importAsyncAPI(String root, path) async {
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
    var versionId = parts[parts.length - 2];
    var specId = parts.last;

    try {
      String contents = await File(path).readAsString();
      var doc = loadYaml(contents);

      // compute mime type from internal format string
      var mimeType;
      var asyncapi = doc["asyncapi"];
      if (asyncapi != null) {
        mimeType = "application/x.asyncapi+gzip;version=" + asyncapi;
      }
      var info = doc["info"];
      var apiTitle = info["title"] ?? "";
      var description = info["description"] ?? "";
      if (description.length > maxDescriptionLength) {
        description = description.substring(0, maxDescriptionLength) + "...";
      }

      print("uploading $apiId $versionId $specId");
      print("$apiTitle");
      print("$description");

      final apiName = projectName + "/apis/" + apiId;
      var api = rpc.Api()
        ..name = apiName
        ..displayName = apiTitle
        ..description = description;
      api.labels["created_from"] = source;
      api.labels["owner"] = owner;
      await this.ensureApiExists(api);

      final versionName = apiName + "/versions/" + versionId;
      var version = rpc.ApiVersion()
        ..name = versionName
        ..displayName = versionId;
      version.labels["created_from"] = source;
      await this.ensureApiVersionExists(version);

      final specName = versionName + "/specs/" + specId;
      if (!await this.apiSpecExists(specName)) {
        var apiSpec = rpc.ApiSpec()
          ..filename = specId
          ..contents = GZipEncoder().encode(Utf8Encoder().convert(contents))
          ..mimeType = mimeType;
        apiSpec.labels["created_from"] = source;
        var request = rpc.CreateApiSpecRequest()
          ..parent = versionName
          ..apiSpecId = specId
          ..apiSpec = apiSpec;
        await this.createApiSpec(request);
      }

      // that's all
    } catch (error) {
      print("$error");
    }
  }

  String filterOwner(String owner) {
    switch (owner) {
      case "googleapis.com":
        return "google";
      default:
        return owner;
    }
  }
}
