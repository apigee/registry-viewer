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

String idForTitle(String title) {
  var id = title.toLowerCase();
  // remove the google prefix because it is applied inconsistently
  if (id.startsWith("google ")) {
    id = id.substring("google ".length);
  }
  // remove anything in parentheses
  if (id.contains("(")) {
    final start = id.indexOf("(");
    final end = id.indexOf(")");
    id = id.substring(0, start - 1) + id.substring(end + 1);
  }
  // remove some superfluous words
  if (id.contains(" api")) {
    id = id.replaceAll(" api", "");
  }
  if (id.contains(" v2")) {
    id = id.replaceAll(" v2", "");
  }
  if (id.contains(" v3")) {
    id = id.replaceAll(" v3", "");
  }
  // make it printable
  id = id.replaceAll("&", "and");
  id = id.replaceAll("/", "");
  id = id.replaceAll(" ", "-");
  // consistently prefix with "google-"
  id = "google-" + id;
  return id;
}

String titleForTitle(String title) {
  if (!title.startsWith("Google ")) {
    title = "Google " + title;
  }
  return title;
}

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel);

  // does the project exist?
  try {
    var request = rpc.GetProjectRequest()..name = "projects/atlas";
    await client.getProject(request, options: rpc.callOptions());
  } catch (error) {
    var project = rpc.Project()
      ..displayName = "Atlas"
      ..description = "APIs from a variety of sources";
    var request = rpc.CreateProjectRequest()
      ..projectId = "atlas"
      ..project = project;
    await client.createProject(request, options: rpc.callOptions());
  }

  // API versions are in directories with names ending with this pattern.
  RegExp versionDirectoryPattern = new RegExp(r"/(v(\d+)((alpha|beta)\d+)?)$");
  String root = (Platform.environment['HOME'] ?? "") + '/Desktop/googleapis';
  Directory dir = Directory(root);
  await Future.forEach(dir.listSync(recursive: true), (entity) async {
    if (entity is Directory) {
      final match = versionDirectoryPattern.firstMatch(entity.path);
      if ((match != null) && (match.group(1) != null)) {
        await importApiSpec(client, root, entity, match.group(1));
      }
    }
  });

  print("done");
  await channel.shutdown();
}

void importApiSpec(
    rpc.RegistryClient client, String root, dir, String version) async {
  // only import APIs with service yaml that specifies their title
  RegExp yamlPattern = new RegExp(r"\.yaml$");
  await Future.forEach(dir.listSync(recursive: false), (entity) async {
    if ((entity is File) &&
        yamlPattern.hasMatch(entity.path) &&
        !entity.path.contains("gapic")) {
      String contents = await File(entity.path).readAsString();
      var doc = loadYaml(contents);
      if (doc["type"] == "google.api.Service") {
        var title = doc["title"];
        print(idForTitle(title) + " " + version);

        String description = "";
        var documentation = doc["documentation"];
        if (documentation != null) {
          var summary = documentation["summary"];
          if (summary != null) {
            description = summary as String;
            description = description.replaceAll("\n", " ");
          }
        }

        await uploadApi(
          client: client,
          root: root,
          dir: dir,
          apiId: idForTitle(title),
          versionId: version,
          title: title,
          description: description,
        );
      }
    }
  });
}

void uploadApi(
    {rpc.RegistryClient client,
    String root,
    Directory dir,
    String apiId,
    String versionId,
    String title,
    String description}) async {
  // does the api exist?
  try {
    var request = rpc.GetApiRequest()..name = "projects/atlas/apis/" + apiId;
    await client.getApi(request, options: rpc.callOptions());
  } catch (error) {
    var api = rpc.Api()
      ..displayName = titleForTitle(title)
      ..description = description;
    api.labels["created-from"] = "googleapis";
    api.labels["google-title"] = title;
    var request = rpc.CreateApiRequest()
      ..parent = "projects/atlas"
      ..apiId = apiId
      ..api = api;
    try {
      await client.createApi(request, options: rpc.callOptions());
    } catch (error) {
      print("${error.runtimeType} $error");
    }
  }
  // does the version exist?
  try {
    var request = rpc.GetApiVersionRequest()
      ..name = "projects/atlas/apis/" + apiId + "/versions/" + versionId;
    await client.getApiVersion(request, options: rpc.callOptions());
  } catch (error) {
    var apiVersion = rpc.ApiVersion()..displayName = versionId;
    apiVersion.labels["created-from"] = "googleapis";
    var request = rpc.CreateApiVersionRequest()
      ..parent = "projects/atlas/apis/" + apiId
      ..apiVersionId = versionId
      ..apiVersion = apiVersion;
    await client.createApiVersion(request, options: rpc.callOptions());
  }
  // does the spec exist?
  try {
    var request = rpc.GetApiSpecRequest()
      ..name = "projects/atlas/apis/" +
          apiId +
          "/versions/" +
          versionId +
          "/specs/protos.zip";
    await client.getApiSpec(request, options: rpc.callOptions());
  } catch (error) {
    var archive = Archive();
    var files = dir.listSync(recursive: false);
    await Future.forEach(files, (file) async {
      if (file is File) {
        var name = file.path.substring(root.length + 1);
        List<int> content = await File(file.path).readAsBytes();
        var archiveFile = ArchiveFile(name, content.length, content);
        print("$name ${content.length}");
        archive.addFile(archiveFile);
      }
    });
    var contents = ZipEncoder().encode(archive);
    print("length ${contents.length}");
    var apiSpec = rpc.ApiSpec()
      ..filename = "protos.zip"
      ..contents = contents
      ..sourceUri = ""
      ..mimeType = "application/x.protobuf+zip";
    apiSpec.labels["created-from"] = "googleapis";
    var request = rpc.CreateApiSpecRequest()
      ..parent = "projects/atlas/apis/" + apiId + "/versions/" + versionId
      ..apiSpecId = "protos.zip"
      ..apiSpec = apiSpec;
    await client.createApiSpec(request, options: rpc.callOptions());
  }
}
