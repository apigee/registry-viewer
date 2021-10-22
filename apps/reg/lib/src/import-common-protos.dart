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

final source = "google-common-protos";

class Entry {
  String api;
  String version;
  String path;
  String title;
  String description;
}

class ImportCommonProtosCommand extends Command {
  final name = "common-protos";
  final description = "Import specs from the Google common protos repository.";

  ImportCommonProtosCommand() {
    this.argParser
      ..addOption(
        'project',
        help: "Project id for imports.",
        valueHelp: "PROJECT",
      )
      ..addOption(
        'path',
        help: "Path to a directory containing the common protos repository.",
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
    final adminClient = rpc.AdminClient(channel, options: rpc.callOptions());

    final projectName = argResults['project'];

    final exists = await adminClient.projectExists(projectName);
    await channel.shutdown();
    if (!exists) {
      throw UsageException("$projectName does not exist", this.argParser.usage);
    }

    String root = argResults['path'];
    List<Entry> entries = [
      Entry()
        ..api = "googleapis.com-api"
        ..version = "v1"
        ..path = 'google/api'
        ..title = "Google API Protos"
        ..description =
            "Also known as 'service config', the schema for configuration of "
                "Google's internal API platform, which handles routing, quotas, "
                "monitoring, logging, and the like.",
      Entry()
        ..api = "googleapis.com-iam"
        ..version = "v1"
        ..path = "google/iam/v1"
        ..title = "Google IAM API"
        ..description = "The Identity and Access Management (IAM) API. "
            "Manages identity and access control for Google Cloud Platform "
            "resources, including the creation of service accounts.",
      Entry()
        ..api = "googleapis.com-iam-admin"
        ..version = "v1"
        ..path = "google/iam/admin/v1"
        ..title = "Google IAM Admin API"
        ..description =
            "Administration API for Identity and Access Management.",
      Entry()
        ..api = "googleapis.com-longrunning"
        ..version = "v1"
        ..path = "google/longrunning"
        ..title = "Google Long-running Operations API"
        ..description = "An abstract interface that manages long running "
            "operations with API services.",
      Entry()
        ..api = "googleapis.com-logging"
        ..version = "v1"
        ..path = "google/logging"
        ..title = "Google Logging Types"
        ..description =
            "Shared types popul;ated by the Stackdriver Logging API and "
                "consumed by other APIs.",
      Entry()
        ..api = "googleapis.com-rpc"
        ..version = "v1"
        ..path = "google/rpc"
        ..title = "Google RPC (Remote Procedure Call) Types"
        ..description = "Types that represent remote procedure call concepts.",
      Entry()
        ..api = "googleapis.com-type"
        ..version = "v1"
        ..path = "google/type"
        ..title = "Google Common Types"
        ..description = "Common types for Google APIs.",
      Entry()
        ..api = "googleapis.com-protobuf"
        ..version = "v1"
        ..path = "google/protobuf"
        ..title = "Google Protobuf Types"
        ..description =
            "Standard types distributed with Google's Protocol Buffers tools.",
    ];

    final Queue<rpc.Task> tasks = Queue();
    for (var entry in entries) {
      tasks.add(ImportCommonProtosTask(root, projectName, entry));
    }
    await rpc.TaskProcessor(tasks, 1).run();
  }
}

class ImportCommonProtosTask implements rpc.Task {
  final String root;
  final String projectName;
  final Entry entry;
  ImportCommonProtosTask(this.root, this.projectName, this.entry);

  String name() => entry.api + " " + entry.version + " " + entry.path;

  void run(rpc.RegistryClient client) async {
    await client.importProtobufApi(root, projectName, entry);
  }
}

extension GoogleApiImporter on rpc.RegistryClient {
  void importProtobufApi(
    String root,
    String projectName,
    Entry entry,
  ) async {
    var apiId = entry.api;
    var versionId = entry.version;

    var apiTitle = entry.title;
    print("apiId: " + apiId);

    var path = entry.path;
    var specId = path.replaceAll("/", "-") + ".zip";
    print("specId: " + specId);

    String description = entry.description;

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

    final dir = Directory(root + "/" + path);
    final specName = versionName + "/specs/" + specId;
    if (!await this.apiSpecExists(specName)) {
      var archive = Archive();
      await Future.forEach(dir.listSync(recursive: true), (file) async {
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
