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
import '../helpers/media.dart';
import '../helpers/root.dart';
import '../helpers/title.dart';

class ProjectDetailPage extends StatelessWidget {
  final String? name;
  const ProjectDetailPage({super.key, this.name});

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
        initialIndex: 1,
        animationDuration: const Duration(milliseconds: 100),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              pageTitle(name) ?? "Project Details",
            ),
            actions: <Widget>[
              homeButton(context),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: "Details"),
                Tab(text: "APIs"),
                Tab(text: "Artifacts"),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    ProjectDetailCard(editable: (root() == "/")),
                    narrow(context)
                        ? const ApiListCard(singleColumn: true)
                        : const CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            view1: ApiListCard(singleColumn: false),
                            view2: ApiDetailCard(
                              selflink: true,
                              editable: true,
                            ),
                          ),
                    narrow(context)
                        ? const ArtifactListCard(
                            SelectionProvider.project,
                            singleColumn: true,
                          )
                        : const CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            view1: ArtifactListCard(
                              SelectionProvider.project,
                              singleColumn: false,
                            ),
                            view2: ArtifactDetailCard(
                              selflink: true,
                              editable: true,
                            ),
                          ),
                  ],
                ),
              ),
              const BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
