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

void reportError(BuildContext context, Object err) {
  if (context != null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // TODO: interpret error to provide actionable guidance.
        return AlertDialog(
          content: Text(
            "$err",
            style: TextStyle(
              fontFamily: "Mono",
              fontSize: 14,
            ),
          ),
          actions: [
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // dismiss dialog
              },
            ),
          ],
        );
      },
    );
  } else {
    print("$err");
  }
}