// Copyright 2020 Google LLC. All Rights Reserved.
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

import 'package:grpc/grpc.dart' as grpc;
import 'dart:io';
import 'package:yaml/yaml.dart';

Config? config;

// This is a stub; this function is only called in web builds.
void setRegistryUserToken(String token) {}

class ConnectionError extends Error {
  final String description;
  ConnectionError(this.description);

  @override
  String toString() {
    return "Error: " + description;
  }
}

grpc.ClientChannel createClientChannel() {
  if (config == null) {
    config = readConfig();
  }
  final insecure = config!.insecure;
  final address = config!.address;

  final parts = address.split(":");
  if (parts.length != 2) {
    throw ConnectionError("registry address must have the form host:port");
  }
  final host = parts[0];
  final port = int.parse(parts[1]);
  final channelOptions = insecure
      ? const grpc.ChannelOptions(
          credentials: const grpc.ChannelCredentials.insecure())
      : const grpc.ChannelOptions(
          credentials: const grpc.ChannelCredentials.secure());
  return grpc.ClientChannel(host, port: port, options: channelOptions);
}

grpc.CallOptions callOptions() {
  if ((config == null) || (config!.token == "")) {
    return grpc.CallOptions();
  }
  Map<String, String> metadata = {"authorization": "Bearer " + config!.token};
  grpc.CallOptions callOptions = grpc.CallOptions(metadata: metadata);
  return callOptions;
}

String? userHome() =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

Config readConfig() {
  if (config != null) {
    return config!;
  }
  String home = userHome()!;
  String configPath = home + "/.config/registry/active_config";
  String contents = new File(configPath).readAsStringSync();
  String activePath = home + "/.config/registry/" + contents;
  contents = new File(activePath).readAsStringSync();
  var doc = loadYaml(contents);
  String address = doc["registry"]["address"];
  bool insecure = doc["registry"]["insecure"];
  String project = doc["registry"]["project"];
  String tokenSource = doc["token-source"];
  config = Config(
      address: address,
      insecure: insecure,
      project: project,
      tokenSource: tokenSource)
    ..fetchToken();
  return config!;
}

class Config {
  final String address;
  final bool insecure;
  final String project;
  final String tokenSource;
  String token = "";
  Config({
    required this.address,
    required this.insecure,
    required this.project,
    required this.tokenSource,
  }) {}
  String toString() {
    return "address=$address insecure=$insecure project=$project tokenSource=$tokenSource token=$token";
  }

  void fetchToken() {
    print("fetching token for $this");
    if (tokenSource != "") {
      var parts = tokenSource.split(" ");
      var result = Process.runSync(parts[0], parts.sublist(1));
      token = result.stdout;
      print("token = $token");
    }
  }
}
