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
import 'dart:io' show Platform;

String? token; // auth token

// unused in non-web builds
void setRegistryUserToken(String token) {}

class ConnectionError extends Error {
  final String description;
  ConnectionError(this.description);

  @override
  String toString() {
    return "Error: " + description;
  }
}

bool unset(String s) {
  return (s == null) || (s == "");
}

grpc.ClientChannel createClientChannel() {
  Map<String, String> env = Platform.environment;
  token = env['APG_REGISTRY_TOKEN'];
  final insecure = env['APG_REGISTRY_INSECURE'] == "1";
  if (!insecure && unset(token!)) {
    throw ConnectionError("APG_REGISTRY_TOKEN not set");
  }
  final address = env['APG_REGISTRY_ADDRESS'];
  if (unset(address!)) {
    throw ConnectionError("APG_REGISTRY_ADDRESS not set");
  }
  final parts = address.split(":");
  if (parts.length != 2) {
    throw ConnectionError("APG_REGISTRY_ADDRESS must have the form host:port");
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
  if (token == null) {
    return grpc.CallOptions();
  }
  Map<String, String> metadata = {"authorization": "Bearer " + token!};
  grpc.CallOptions callOptions = grpc.CallOptions(metadata: metadata);
  return callOptions;
}
