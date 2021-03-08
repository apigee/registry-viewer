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
import 'detail_rows.dart';

class RegistryDetailCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyText2;
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyRow(
                  "The API Registry is an online catalog and storehouse of information about APIs.",
                  style: textStyle,
                ),
                BodyRow(
                    "Each project below contains a sample API collection that might be built by an API Registry user.",
                    style: textStyle),
                LinkifiedBodyRow(
                  "See https://apigee.github.io/registry to learn more about the API behind the API Registry.",
                  style: textStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
