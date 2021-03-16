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

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;

final projectDescription = "APIs from a variety of sources";
final projectDisplayName = "Motley APIs";
final projectName = "projects/motley";
final source = "discovery";

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  await client.ensureProjectExists(rpc.Project()
    ..name = projectName
    ..displayName = projectDisplayName
    ..description = projectDescription);

  for (var item in await fetchApiListings()) {
    await client.importDiscoveryAPI(item);
  }

  await channel.shutdown();
}

Future<List<dynamic>> fetchApiListings() {
  return http
      .get(Uri.parse('https://www.googleapis.com/discovery/v1/apis'))
      .then((response) {
    Map<String, dynamic> discoveryList = jsonDecode(response.body);
    return discoveryList["items"];
  });
}

extension DiscoveryImporter on rpc.RegistryClient {
  void importDiscoveryAPI(item) async {
    // get basic API attributes from the Discovery Service list
    var dict = item as Map<String, dynamic>;
    var title = dict["title"];
    var apiId = GoogleApis.idForTitle(title);
    var apiTitle = GoogleApis.titleForTitle(title);
    var versionId = dict["version"] as String;

    // read the discovery doc
    var discoveryUrl = dict["discoveryRestUrl"] as String;
    var doc = await http.get(Uri.parse(discoveryUrl));
    Map<String, dynamic> discoveryDoc = jsonDecode(doc.body);
    var description = discoveryDoc["description"] ?? "";

    print("uploading $apiId $versionId");

    final apiName = projectName + "/apis/" + apiId;
    var api = rpc.Api()
      ..name = apiName
      ..displayName = apiTitle
      ..description = description;
    api.labels["created_from"] = source;
    api.labels["owner"] = "google";
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
