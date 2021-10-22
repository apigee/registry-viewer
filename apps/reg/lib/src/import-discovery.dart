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

import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;

final source = "discovery";

class ImportDiscoveryCommand extends Command {
  final name = "discovery";
  final description = "Import specs from the Google API Discovery Service.";

  ImportDiscoveryCommand() {
    this.argParser
      ..addOption(
        'project',
        help: "Project for imports.",
        valueHelp: "PROJECT",
      );
  }

  void run() async {
    if (argResults['project'] == null) {
      throw UsageException("Please specify --project", this.argParser.usage);
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

    final Queue<rpc.Task> tasks = Queue();

    for (var item in await fetchApiListings()) {
      tasks.add(ImportDiscoveryTask(item, projectName));
    }

    await rpc.TaskProcessor(tasks, 64).run();
  }
}

Future<List<dynamic>> fetchApiListings() {
  return http
      .get(Uri.parse('https://www.googleapis.com/discovery/v1/apis'))
      .then((response) {
    Map<String, dynamic> discoveryList = jsonDecode(response.body);
    return discoveryList["items"];
  });
}

class ImportDiscoveryTask implements rpc.Task {
  final item;
  final projectName;

  ImportDiscoveryTask(this.item, this.projectName);

  String name() {
    final map = item as Map<String, dynamic>;
    return map["name"] + " " + map["version"];
  }

  void run(rpc.RegistryClient client) async {
    await client.importDiscoveryAPI(item, projectName);
  }
}

String filterOwner(String owner) {
  owner = (owner ?? "Google").toLowerCase();
  if (owner == "google") {
    owner = "googleapis.com";
  }
  return owner;
}

extension DiscoveryImporter on rpc.RegistryClient {
  void importDiscoveryAPI(item, projectName) async {
    // get basic API attributes from the Discovery Service list
    var dict = item as Map<String, dynamic>;
    var title = dict["title"];
    var apiId = filterOwner(dict["owner"]) + "-" + dict["name"].toLowerCase();
    var apiTitle = GoogleApis.titleForTitle(title);
    var versionId = dict["version"] as String;

    // read the discovery doc
    var discoveryUrl = dict["discoveryRestUrl"] as String;
    var doc = await http.get(Uri.parse(discoveryUrl));
    Map<String, dynamic> discoveryDoc = jsonDecode(doc.body);
    var description = discoveryDoc["description"] ?? "";

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

    final specName = versionName + "/specs/discovery.json";
    if (!await this.apiSpecExists(specName)) {
      try {
        var contents = GZipEncoder().encode(doc.bodyBytes);
        var apiSpec = rpc.ApiSpec()
          ..filename = "discovery.json"
          ..contents = contents
          ..sourceUri = discoveryUrl
          ..mimeType = "application/x.discovery+gzip";
        apiSpec.labels["created_from"] = source;
        var revision = discoveryDoc["revision"];
        if (revision != null) {
          apiSpec.labels["revision-date"] = revision;
        }
        var request = rpc.CreateApiSpecRequest()
          ..parent = versionName
          ..apiSpecId = specName.split("/").last
          ..apiSpec = apiSpec;
        await this.createApiSpec(request);
      } catch (error) {
        print("$error");
        print(discoveryUrl);
        print(doc.body.toString());
      }
    }
  }
}
