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
import 'dart:collection';
import 'dart:isolate';

import 'grpc_client.dart';
import 'generated/google/cloud/apigee/registry/v1/registry_service.pbgrpc.dart';

abstract class Task {
  void run(RegistryClient client);
  String name();
}

class TaskProcessor {
  final Queue<Task> queue;
  final int width;
  TaskProcessor(this.queue, this.width);

  void run() async {
    var futures = <Future>[];
    for (var i = 0; i < width; i++) {
      futures.add(startWorker(i, queue));
    }
    await Future.wait(futures);
  }

  Future startWorker(int i, Queue tasks) async {
    String id = "$i".padLeft(3, "0");
    Completer completer = new Completer();
    ReceivePort isolateToMainStream = ReceivePort();
    SendPort mainToIsolateStream;
    Future<Isolate> myIsolateInstance;
    isolateToMainStream.listen((data) {
      if (data is SendPort) {
        mainToIsolateStream = data;
        mainToIsolateStream.send("#$id");
      } else if (data is String) {
        print("[$id]-> $data");
        if (data == "ready") {
          if (tasks.length > 0) {
            var task = tasks.removeFirst();
            mainToIsolateStream?.send(task);
          } else {
            mainToIsolateStream?.send("stop");
          }
        } else if (data == "done") {
          print("closing [$id]");
          myIsolateInstance.then((isolate) {
            isolateToMainStream.close();
          });
          completer.complete();
        } else {
          print('[isolateToMainStream] $data');
        }
      }
    });
    myIsolateInstance = Isolate.spawn(runWorker, isolateToMainStream.sendPort);
    return completer.future;
  }

  static void runWorker(SendPort isolateToMainStream) {
    final channel = createClientChannel();
    final client = RegistryClient(channel, options: callOptions());
    String id = "   ";
    ReceivePort mainToIsolateStream = ReceivePort();
    isolateToMainStream.send(mainToIsolateStream.sendPort);
    mainToIsolateStream.listen((data) async {
      if (data is String) {
        print('->[$id] $data');
        if (data[0] == "#") {
          id = data.substring(1);
          isolateToMainStream.send('ready');
        } else if (data == "stop") {
          await channel.shutdown();
          isolateToMainStream.send('done');
        }
      } else if (data is Task) {
        print('->[$id] ${data.name()}');
        try {
          await data.run(client);
        } catch (error) {
          print("$error");
        }
        isolateToMainStream.send('ready');
      }
    });
  }
}
