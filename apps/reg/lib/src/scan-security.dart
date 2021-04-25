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
import 'package:yaml/yaml.dart';

final source = "discovery";

String versionName;

class ScanSecurityCommand extends Command {
  final name = "security";
  final description = "Scan security fields in OpenAPI specs.";

  ScanSecurityCommand() {
    this.argParser
      ..addOption(
        'version',
        help: "Version to scan (may include wildcards).",
        valueHelp: "VERSION_ID",
      );
  }

  void run() async {
    if (argResults['version'] == null) {
      throw UsageException("Please specify --version", this.argParser.usage);
    }

    versionName = argResults['version'];

    final channel = rpc.createClientChannel();
    final client = rpc.RegistryClient(channel, options: rpc.callOptions());

    await rpc.listAPISpecs(
      client,
      parent: versionName,
      f: (spec) async {
        var format = typeFromMimeType(spec.mimeType);
        if (format == "openapi") {
          var request = rpc.GetApiSpecRequest()
            ..name = spec.name
            ..view = rpc.View.FULL;
          var fullSpec = await client.getApiSpec(request);
          try {
            var contents =
                utf8.decode(GZipDecoder().decodeBytes(fullSpec.contents));
            var doc = loadYaml(contents);
            if (doc["swagger"] != null) {
              // look for openapi v2 security
              var security = doc["security"];
              var securityDefinitions = doc["securityDefinitions"];
              if ((security != null) || (securityDefinitions != null)) {
                print("${spec.name}");
                print("security: $security");
                print("securityDefinitions: $securityDefinitions");
                print("----------------------------");
              }
            }
            if (doc["openapi"] != null) {
              // look for openapi v3 security
              var security = doc["security"];
              var securitySchemes = null;
              if (doc["components"] != null) {
                securitySchemes = doc["components"]["securitySchemes"];
              }
              if ((security != null) || (securitySchemes != null)) {
                print("${spec.name}");
                print("security: $security");
                print("securitySchemes: $securitySchemes");
                print("----------------------------");
              }
            }
          } catch (error) {
            print("Error in ${spec.name}");
            print("$error");
          }
        }
      },
    );

    await channel.shutdown();
  }
}

String typeFromMimeType(String mimeType) {
  RegExp mimeTypePattern = new RegExp(r"^application/x.([^\+;]*)(.*)?$");
  var match = mimeTypePattern.firstMatch(mimeType);
  if (match != null) {
    return match.group(1);
  }
  return mimeType;
}