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
import '../components/project_list.dart';
import '../components/project_detail.dart';
import '../components/registry_detail.dart';
import '../models/selection.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    return SelectionProvider(
      selection: selection,
      child: Container(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: RegistryDetailCard(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Row(
                children: [
                  Expanded(
                    child: ProjectListCard(),
                  ),
                  Expanded(
                    child: ProjectDetailCard(selflink: true, editable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
