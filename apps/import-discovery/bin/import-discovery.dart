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
import 'package:registry/registry.dart' as rpc;
import 'package:importer/importer.dart';

final projectName = "projects/motley";
final projectDisplayName = "Motley APIs";
final projectDescription = "APIs from a variety of sources";

Future<List<dynamic>> fetchApiListings() {
  return http
      .get(Uri.parse('https://www.googleapis.com/discovery/v1/apis'))
      .then((response) {
    Map<String, dynamic> discoveryList = jsonDecode(response.body);
    return discoveryList["items"];
  });
}

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  client.ensureProjectExists(rpc.Project()
    ..name = projectName
    ..displayName = projectDisplayName
    ..description = projectDescription);

  for (var item in await fetchApiListings()) {
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
    api.labels["created-from"] = "discovery";
    api.labels["google-title"] = title;
    await client.ensureApiExists(api);

    final versionName = apiName + "/versions/" + versionId;
    var version = rpc.ApiVersion()
      ..name = versionName
      ..displayName = versionId;
    version.labels["created-from"] = "discovery";
    await client.ensureApiVersionExists(version);

    final specName = versionName + "/specs/discovery.json";
    if (!await client.apiSpecExists(specName)) {
      try {
        var contents = GZipEncoder().encode(doc.bodyBytes);
        var apiSpec = rpc.ApiSpec()
          ..filename = "discovery.json"
          ..contents = contents
          ..sourceUri = discoveryUrl
          ..mimeType = "application/x.discovery+gzip";
        apiSpec.labels["created-from"] = "discovery";
        var revision = discoveryDoc["revision"];
        if (revision != null) {
          apiSpec.labels["revision-date"] = revision;
        }
        var request = rpc.CreateApiSpecRequest()
          ..parent = "projects/motley/apis/" + apiId + "/versions/" + versionId
          ..apiSpecId = "discovery.json"
          ..apiSpec = apiSpec;
        await client.createApiSpec(request);
      } catch (error) {
        print("$error");
        print(discoveryUrl);
        print(doc.body.toString());
      }
    }
  }

  await channel.shutdown();
}
