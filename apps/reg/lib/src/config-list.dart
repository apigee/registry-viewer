// Copyright 2023 Google LLC. All Rights Reserved.
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

import 'dart:io';
import 'dart:io' show Platform;
import 'package:args/command_runner.dart';
import 'package:registry/registry.dart';
import 'package:yaml/yaml.dart';

String? userHome() =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

class ConfigListCommand extends Command {
  final name = "list";
  final description = "Display the current registry configuration.";

  ConfigCommand() {}

  void run() async {
    String home = userHome()!;
    String configPath = home + "/.config/registry/active_config";
    String contents = new File(configPath).readAsStringSync();
    print(contents);

    String activePath = home + "/.config/registry/" + contents;
    contents = new File(activePath).readAsStringSync();
    print(contents);

    var doc = loadYaml(contents);
    print(doc);

    var registry_address = doc["registry"]["address"];
    print("address = $registry_address");

    var registry_insecure = doc["registry"]["insecure"];
    print("insecure = $registry_insecure");

    var registry_project = doc["registry"]["project"];
    print("project = $registry_project");

    var token_source = doc["token-source"];
    print("token source = $token_source");

    var parts = token_source.split(" ");
    var result = await Process.run(parts[0], parts.sublist(1));

    String token = result.stdout;
    print("token = $token");
  }
}
