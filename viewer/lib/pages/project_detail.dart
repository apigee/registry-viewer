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
import '../components/project_detail.dart';
import '../components/api_list.dart';
import '../components/api_detail.dart';
import '../components/artifact_list.dart';
import '../components/artifact_detail.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';
import '../components/split_view.dart';
import '../helpers/root.dart';
import '../helpers/tab_decoration.dart';
import '../helpers/title.dart';

class ProjectDetailPage extends StatelessWidget {
  final String? name;
  ProjectDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      selection.updateProjectName(name!.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: DefaultTabController(
        length: 3,
        animationDuration: Duration.zero,
        initialIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              pageTitle(this.name) ?? "Project Details",
            ),
            actions: <Widget>[
              homeButton(context),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: "Details"),
                Tab(text: "APIs"),
                Tab(text: "Artifacts"),
              ],
              indicator: tabDecoration(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    ProjectDetailCard(editable: (root() == "/")),
                    CustomSplitView(
                      viewMode: SplitViewMode.Horizontal,
                      initialWeight: 0.33,
                      view1: ApiListCard(),
                      view2: ApiDetailCard(
                        selflink: true,
                        editable: true,
                      ),
                    ),
                    CustomSplitView(
                      viewMode: SplitViewMode.Horizontal,
                      initialWeight: 0.5,
                      view1: ArtifactListCard(SelectionProvider.project),
                      view2: ArtifactDetailCard(
                        selflink: true,
                        editable: true,
                      ),
                    ),
                  ],
                ),
              ),
              BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
