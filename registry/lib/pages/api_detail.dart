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
import '../models/selection.dart';
import '../components/api_detail.dart';
import '../components/version_detail.dart';
import '../components/version_list.dart';
import '../components/label_list.dart';
import '../components/property_list.dart';
import '../components/property_detail.dart';

class ApiDetailPage extends StatelessWidget {
  final String name;
  ApiDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      selection.updateApiName(name.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "API Details",
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 4,
              child: Row(children: [
                Expanded(child: ApiDetailCard(editable: true)),
                Expanded(child: PropertyListCard(SelectionProvider.api)),
                Expanded(
                  child: PropertyDetailCard(
                    selflink: true,
                    editable: true,
                  ),
                ),
              ]),
            ),
            Expanded(
              flex: 4,
              child: Row(children: [
                Expanded(
                  flex: 1,
                  child: LabelListCard(SelectionProvider.api),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox.expand(child: VersionListCard()),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox.expand(
                    child: VersionDetailCard(
                      selflink: true,
                      editable: true,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
