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
import 'package:split_view/split_view.dart';
import '../models/selection.dart';
import '../components/api_detail.dart';
import '../components/version_detail.dart';
import '../components/version_list.dart';
import '../components/artifact_list.dart';
import '../components/artifact_detail.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';

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
          actions: <Widget>[
            homeButton(context),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SplitView(
                  viewMode: SplitViewMode.Vertical,
                  initialWeight: 0.33,
                  view1: SplitView(
                    viewMode: SplitViewMode.Horizontal,
                    view1: ApiDetailCard(editable: true),
                    view2: SplitView(
                      viewMode: SplitViewMode.Horizontal,
                      initialWeight: 0.33,
                      view1: ArtifactListCard(SelectionProvider.api),
                      view2: ArtifactDetailCard(
                        selflink: true,
                        editable: true,
                      ),
                    ),
                  ),
                  view2: SplitView(
                    viewMode: SplitViewMode.Horizontal,
                    initialWeight: 0.33,
                    view1: VersionListCard(),
                    view2: VersionDetailCard(
                      selflink: true,
                      editable: true,
                    ),
                  )),
            ),
            BottomBar(),
          ],
        ),
      ),
    );
  }
}
