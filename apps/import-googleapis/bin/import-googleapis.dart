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

import 'dart:typed_data';

import 'package:registry/registry.dart' as rpc;
import 'package:archive/archive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:yaml/yaml.dart';
import 'package:importer/importer.dart';

final projectName = "projects/motley";
final projectDisplayName = "Motley APIs";
final projectDescription = "APIs from a variety of sources";

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  client.ensureProjectExists(rpc.Project()
    ..name = projectName
    ..displayName = projectDisplayName
    ..description = projectDescription);

  // This assumes the googleapis repo is checked out in ~/Desktop/googleapis
  String root = (Platform.environment['HOME'] ?? "") + '/Desktop/googleapis';

  // API versions are in directories with names ending with this pattern.
  RegExp versionDirectoryPattern = new RegExp(r"/(v(\d+)((alpha|beta)\d+)?)$");
  await Future.forEach(Directory(root).listSync(recursive: true),
      (entity) async {
    if (entity is Directory) {
      final match = versionDirectoryPattern.firstMatch(entity.path);
      if ((match != null) && (match.group(1) != null)) {
        await client.importProtobufApi(root, entity, match.group(1));
      }
    }
  });

  print("done");
  await channel.shutdown();
}

extension GoogleApiImporter on rpc.RegistryClient {
  void importProtobufApi(String root, dir, String versionId) async {
    // only import APIs with service yaml that specifies their title
    RegExp yamlPattern = new RegExp(r"\.yaml$");
    await Future.forEach(dir.listSync(recursive: false), (entity) async {
      if ((entity is File) &&
          yamlPattern.hasMatch(entity.path) &&
          !entity.path.contains("gapic")) {
        String contents = await File(entity.path).readAsString();
        var doc = loadYaml(contents);
        if ((doc["type"] == "google.api.Service") && (doc["title"] != null)) {
          var title = doc["title"];
          var apiId = GoogleApis.idForTitle(title);
          var apiTitle = GoogleApis.titleForTitle(title);

          String description = "";
          var documentation = doc["documentation"];
          if (documentation != null) {
            var summary = documentation["summary"];
            if (summary != null) {
              description = summary as String;
              description = description.replaceAll("\n", " ");
            }
          }

          print("uploading $apiId $versionId");

          final apiName = projectName + "/apis/" + apiId;
          var api = rpc.Api()
            ..name = apiName
            ..displayName = apiTitle
            ..description = description;
          api.labels["created-from"] = "googleapis";
          api.labels["google-title"] = title;
          await this.ensureApiExists(api);

          final versionName = apiName + "/versions/" + versionId;
          var version = rpc.ApiVersion()
            ..name = versionName
            ..displayName = versionId;
          version.labels["created-from"] = "googleapis";
          await this.ensureApiVersionExists(version);

          final specName = versionName + "/specs/protos.zip";
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
              ..filename = "protos.zip"
              ..contents = ZipEncoder().encode(archive)
              ..sourceUri = ""
              ..mimeType = "application/x.protobuf+zip";
            apiSpec.labels["created-from"] = "googleapis";
            var request = rpc.CreateApiSpecRequest()
              ..parent =
                  "projects/motley/apis/" + apiId + "/versions/" + versionId
              ..apiSpecId = "protos.zip"
              ..apiSpec = apiSpec;
            await this.createApiSpec(request, options: rpc.callOptions());
          }
        }
      }
    });
  }
}
