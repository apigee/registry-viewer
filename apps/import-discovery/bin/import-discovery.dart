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

class DiscoveryApiListing {
  String id;
  String version;
  String title;
  String discoveryUrl;
  DiscoveryApiListing({this.id, this.version, this.title, this.discoveryUrl});
}

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
  final client = rpc.RegistryClient(channel);

  // does the project exist?
  try {
    var request = rpc.GetProjectRequest()..name = "projects/motley";
    await client.getProject(request, options: rpc.callOptions());
  } catch (error) {
    var project = rpc.Project()
      ..displayName = "Motley"
      ..description = "APIs from a variety of sources";
    var request = rpc.CreateProjectRequest()
      ..projectId = "motley"
      ..project = project;
    await client.createProject(request, options: rpc.callOptions());
  }

  final listings = await fetchApiListings();
  for (var item in listings) {
    var dict = item as Map<String, dynamic>;
    var id = idForTitle(dict["title"] as String);
    var version = dict["version"] as String;
    var title = titleForTitle(dict["title"] as String);
    var discoveryUrl = dict["discoveryRestUrl"] as String;
    print(id + " " + version);
    // does the api exist?
    try {
      var request = rpc.GetApiRequest()..name = "projects/motley/apis/" + id;
      await client.getApi(request, options: rpc.callOptions());
    } catch (error) {
      var api = rpc.Api()..displayName = title;
      api.labels["created-from"] = "discovery";
      var request = rpc.CreateApiRequest()
        ..parent = "projects/motley"
        ..apiId = id
        ..api = api;
      await client.createApi(request, options: rpc.callOptions());
    }
    // does the version exist?
    try {
      var request = rpc.GetApiVersionRequest()
        ..name = "projects/motley/apis/" + id + "/versions/" + version;
      await client.getApiVersion(request, options: rpc.callOptions());
    } catch (error) {
      var apiVersion = rpc.ApiVersion()..displayName = version;
      apiVersion.labels["created-from"] = "discovery";
      var request = rpc.CreateApiVersionRequest()
        ..parent = "projects/motley/apis/" + id
        ..apiVersionId = version
        ..apiVersion = apiVersion;
      await client.createApiVersion(request, options: rpc.callOptions());
    }
    // does the spec exist?
    try {
      var request = rpc.GetApiSpecRequest()
        ..name = "projects/motley/apis/" +
            id +
            "/versions/" +
            version +
            "/specs/discovery.json";
      await client.getApiSpec(request, options: rpc.callOptions());
    } catch (error) {
      var doc = await http.get(Uri.parse(discoveryUrl));
      try {
        Map<String, dynamic> discoveryDoc = jsonDecode(doc.body);
        var contents = GZipEncoder().encode(doc.bodyBytes);
        var apiSpec = rpc.ApiSpec()
          ..filename = "discovery.json"
          ..contents = contents
          ..sourceUri = discoveryUrl
          ..mimeType = "application/x.discovery+gzip";
        apiSpec.labels["created-from"] = "discovery";
        var revision = discoveryDoc["revision"] as String;
        if (revision != null) {
          apiSpec.labels["revision-date"] = revision;
        }

        var request = rpc.CreateApiSpecRequest()
          ..parent = "projects/motley/apis/" + id + "/versions/" + version
          ..apiSpecId = "discovery.json"
          ..apiSpec = apiSpec;
        await client.createApiSpec(request, options: rpc.callOptions());
        // use the spec to update the API description
        var description = discoveryDoc["description"] as String;
        var title = discoveryDoc["title"] as String;
        var getRequest = rpc.GetApiRequest()
          ..name = "projects/motley/apis/" + id;
        var api = await client.getApi(getRequest, options: rpc.callOptions());
        api.description = description ?? "";
        api.labels["google-title"] = title ?? "";
        var updateRequest = rpc.UpdateApiRequest()
          ..api = api
          ..updateMask = rpc.FieldMask(paths: ["description", "labels"]);
        await client.updateApi(updateRequest, options: rpc.callOptions());
      } catch (error) {
        print("$error");
        print(discoveryUrl);
        print(doc.body.toString());
      }
    }
  }

  await channel.shutdown();
}
