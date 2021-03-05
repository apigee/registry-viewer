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

Widget filterBar(
  BuildContext context,
  Widget filterField, {
  String type,
  Function add,
  Function refresh,
}) {
  String tooltip = "Add";
  if (type != null) {
    tooltip += " " + type;
  }
  return AppBar(
    backgroundColor: Theme.of(context).secondaryHeaderColor,
    primary: false,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: filterField,
    actions: <Widget>[
      IconButton(
        color: Colors.black,
        icon: Icon(Icons.refresh),
        tooltip: "refresh",
        onPressed: refresh,
      ),
      if (type != null)
        IconButton(
          color: Colors.black,
          icon: Icon(Icons.add),
          tooltip: tooltip,
          onPressed: add,
        ),
    ],
  );
}
