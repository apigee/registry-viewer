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
import 'dart:io';

String typeFromMimeType(String mimeType) {
  RegExp mimeTypePattern = new RegExp(r"^application/x.([^\+;]*)(.*)?$");
  var match = mimeTypePattern.firstMatch(mimeType);
  if (match != null) {
    return match.group(1);
  }
  return mimeType;
}

class ComputeSummaryCommand extends Command {
  final name = "summary";
  final description = "Compute a summary of a project.";

  ComputeSummaryCommand() {
    this.argParser
      ..addOption(
        'project',
        help: "Project.",
        valueHelp: "PROJECT",
      );
  }

  void run() async {
    if (argResults['project'] == null) {
      throw UsageException("Please specify --project", this.argParser.usage);
    }

    final projectName = argResults['version'];

    final channel = rpc.createClientChannel();
    final client = rpc.RegistryClient(channel, options: rpc.callOptions());
    var apiCount = 0;
    Map<String, int> owners = Map();
    await rpc.listAPIs(
      client,
      parent: projectName,
      f: (api) async {
        var owner = api.labels["owner"];
        if (owner == null) return;
        if (owners[owner] == null) {
          owners[owner] = 0;
        }
        owners[owner]++;
        apiCount++;
      },
    );

    var versionCount = 0;
    await rpc.listAPIVersions(
      client,
      parent: projectName + "/apis/-",
      f: (version) async {
        versionCount++;
      },
    );

    var specCount = 0;
    Map<String, int> formats = Map();
    await rpc.listAPISpecs(
      client,
      parent: projectName + "/apis/-/versions/-",
      f: (spec) async {
        var format = typeFromMimeType(spec.mimeType);
        if (formats[format] == null) {
          formats[format] = 0;
        }
        formats[format]++;
        specCount++;
      },
    );

    var summary = rpc.RegistrySummary()
      ..apiCount = apiCount
      ..versionCount = versionCount
      ..specCount = specCount;

    formats.forEach((k, v) => summary.formats.add(rpc.RegistryWordCount()
      ..word = k
      ..count = v));
    summary.formats.sort((a, b) => -a.count.compareTo(b.count));
    owners.forEach((k, v) => summary.owners.add(rpc.RegistryWordCount()
      ..word = k
      ..count = v));
    summary.owners.sort((a, b) => -a.count.compareTo(b.count));

    print("$summary");

    var artifact = rpc.Artifact()
      ..name = projectName + "/artifacts/summary"
      ..mimeType =
          "application/octet-stream;type=google.cloud.apigee.registry.applications.v1alpha1.RegistrySummary"
      ..contents = summary.writeToBuffer();
    var createRequest = rpc.CreateArtifactRequest()
      ..parent = projectName
      ..artifactId = "summary"
      ..artifact = artifact;
    try {
      var createResponse = await client.createArtifact(createRequest);
    } catch (error) {
      var replaceRequest = rpc.ReplaceArtifactRequest()..artifact = artifact;
      var replaceResponse = await client.replaceArtifact(replaceRequest);
    }

    await channel.shutdown();
  }
}
