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
import '../build.dart';

class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final white =
        Theme.of(context).textTheme.bodyText2!.copyWith(color: Colors.white);
    return Container(
      color: Colors.grey[700], // Theme.of(context).primaryColor,
      padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "Built $buildTime",
              style: white,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
          Flexible(
            child: Text(
              "Commit $commitHash",
              style: white,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}
