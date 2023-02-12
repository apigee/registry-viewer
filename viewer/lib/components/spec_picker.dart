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
import 'project_list.dart';
import 'api_list.dart';
import 'version_list.dart';
import 'spec_list.dart';
import 'project_detail.dart';
import 'api_detail.dart';
import 'version_detail.dart';
import 'spec_detail.dart';
import '../models/selection.dart';

class SpecPicker extends StatelessWidget {
  const SpecPicker({super.key});
  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    return SelectionProvider(
      selection: selection,
      child: Container(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: const [
                  Expanded(
                    child: ProjectListCard(
                      singleColumn: false,
                    ),
                  ),
                  Expanded(
                    child: ApiListCard(
                      singleColumn: false,
                    ),
                  ),
                  Expanded(
                    child: VersionListCard(
                      singleColumn: false,
                    ),
                  ),
                  Expanded(
                    child: SpecListCard(singleColumn: false),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: const [
                  Expanded(
                    child: SizedBox.expand(child: ProjectDetailCard()),
                  ),
                  Expanded(
                    child: SizedBox.expand(child: ApiDetailCard()),
                  ),
                  Expanded(
                    child: SizedBox.expand(child: VersionDetailCard()),
                  ),
                  Expanded(
                    child: SizedBox.expand(child: SpecDetailCard()),
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
