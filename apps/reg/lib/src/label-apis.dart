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

import 'package:args/command_runner.dart';
import 'package:registry/registry.dart' as rpc;

class LabelAPIsCommand extends Command {
  final name = "apis";
  final description = "Label APIs with computed properties.";

  LabelAPIsCommand() {
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

    final projectName = argResults['project'];

    final channel = rpc.createClientChannel();
    final client = rpc.RegistryClient(channel, options: rpc.callOptions());

    final Queue<rpc.Task> tasks = Queue();
    await rpc.listAPIs(
      client,
      parent: projectName,
      f: (api) async {
        print(api.name);
        tasks.add(LabelApiTask(api.name));
      },
    );

    await channel.shutdown();

    await rpc.TaskProcessor(tasks, 64).run();
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

class LabelApiTask implements rpc.Task {
  final String apiName;
  LabelApiTask(this.apiName);

  String name() => apiName;

  void run(rpc.RegistryClient client) async {
    var getRequest = rpc.GetApiRequest()..name = apiName;
    rpc.Api api = await client.getApi(getRequest);

    int versionCount = 0;
    int specCount = 0;
    Map<String, bool> apiSpecTypes = {};
    await rpc.listAPIVersions(
      client,
      parent: apiName,
      f: (version) async {
        versionCount++;
        Map<String, bool> versionSpecTypes = {};
        await rpc.listAPISpecs(client, parent: version.name, f: (spec) {
          specCount++;
          var type = typeFromMimeType(spec.mimeType);
          apiSpecTypes[type] = true;
          versionSpecTypes[type] = true;
        });
        for (var key in versionSpecTypes.keys) {
          version.labels[key] = "true";
        }
        var updateRequest = rpc.UpdateApiVersionRequest()
          ..apiVersion = version
          ..updateMask = (rpc.FieldMask()..paths.add("labels"));
        await client.updateApiVersion(updateRequest);
      },
    );
    api.labels["versions"] = "$versionCount";
    api.labels["specs"] = "$specCount";
    for (var key in apiSpecTypes.keys) {
      api.labels[key] = "true";
    }
    var updateRequest = rpc.UpdateApiRequest()
      ..api = api
      ..updateMask = (rpc.FieldMask()..paths.add("labels"));
    await client.updateApi(updateRequest);
  }
}
