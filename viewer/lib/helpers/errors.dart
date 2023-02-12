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

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart' as grpc;

void reportError(BuildContext? context, Object? error) {
  if (context != null) {
    Future.delayed(const Duration(), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String? message;
          if (error is grpc.GrpcError) {
            message = error.message;
            message ??= "$error";
          }
          return AlertDialog(
            content: Text(message!),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                },
              ),
            ],
          );
        },
      );
    });
  } else {
    debugPrint("$error");
  }
}

Function onError(BuildContext context) {
  return (error) => reportError(context, error);
}
