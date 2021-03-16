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

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:importer/importer.dart';
import 'package:registry/registry.dart' as rpc;
import 'package:yaml/yaml.dart';

final projectDescription = "APIs from a variety of sources";
final projectDisplayName = "Motley APIs";
final projectName = "projects/motley";
final source = "openapi_directory";

String typeFromMimeType(String mimeType) {
  RegExp mimeTypePattern = new RegExp(r"^application/x.([^\+;]*)(.*)?$");
  var match = mimeTypePattern.firstMatch(mimeType);
  if (match != null) {
    return match.group(1);
  }
  return mimeType;
}

void main(List<String> arguments) async {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  await client.ensureProjectExists(rpc.Project()
    ..name = projectName
    ..displayName = projectDisplayName
    ..description = projectDescription);

  final Queue<String> apiNames = Queue();

  await rpc.listAPIs(
    client,
    parent: projectName,
    f: (api) async {
      print(api.name);
      apiNames.add(api.name);
    },
  );
  await channel.shutdown();

  var futures = <Future>[];
  for (var i = 0; i < 256; i++) {
    futures.add(initIsolate(i, apiNames));
  }
  await Future.wait(futures);
  print("everything is done");
}

Future initIsolate(int i, Queue apiNames) async {
  Completer completer = new Completer();
  ReceivePort isolateToMainStream = ReceivePort();
  SendPort mainToIsolateStream;

  Future<Isolate> myIsolateInstance;

  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      mainToIsolateStream = data;
      mainToIsolateStream.send("# $i");
    } else if (data is String) {
      if (data == "ready") {
        if (apiNames.length > 0) {
          var name = apiNames.removeFirst();
          mainToIsolateStream?.send(name);
        } else {
          mainToIsolateStream?.send("quit");
        }
      } else if (data == "done") {
        print("closing $i");
        myIsolateInstance.then((isolate) {
          isolateToMainStream.close();
        });
        print("completing $i");
        completer.complete();
      } else {
        print('[isolateToMainStream] $data');
      }
    }
  });

  myIsolateInstance = Isolate.spawn(runWorker, isolateToMainStream.sendPort);

  return completer.future;
}

void runWorker(SendPort isolateToMainStream) {
  final channel = rpc.createClientChannel();
  final client = rpc.RegistryClient(channel, options: rpc.callOptions());

  int id = -1;

  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);
  mainToIsolateStream.listen((data) async {
    print('[mainToIsolateStream $id] $data');
    if (data[0] == "#") {
      id = int.parse(data.substring(2));
      isolateToMainStream.send('ready');
    } else if (data == "quit") {
      await channel.shutdown();
      isolateToMainStream.send('done');
    } else {
      await labelApi(client, data);
      isolateToMainStream.send('ready');
    }
  });
}

void labelApi(rpc.RegistryClient client, String apiName) async {
  var getRequest = rpc.GetApiRequest()..name = apiName;
  rpc.Api api = await client.getApi(getRequest);

  int versionCount = 0;
  Map<String, bool> apiSpecTypes = {};
  await rpc.listAPIVersions(client, parent: apiName, f: (version) async {
    versionCount++;
    Map<String, bool> versionSpecTypes = {};
    await rpc.listAPISpecs(client, parent: version.name, f: (spec) {
      var type = typeFromMimeType(spec.mimeType);
      apiSpecTypes[type] = true;
      versionSpecTypes[type] = true;
    });
    for (var key in apiSpecTypes.keys) {
      version.labels[key] = "true";
    }
    var updateRequest = rpc.UpdateApiVersionRequest()
      ..apiVersion = version
      ..updateMask = (rpc.FieldMask()..paths.add("labels"));
    await client.updateApiVersion(updateRequest);
  });
  api.labels["versions"] = "$versionCount";
  for (var key in apiSpecTypes.keys) {
    api.labels[key] = "true";
  }
  var updateRequest = rpc.UpdateApiRequest()
    ..api = api
    ..updateMask = (rpc.FieldMask()..paths.add("labels"));
  await client.updateApi(updateRequest);
}
