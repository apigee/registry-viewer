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
import '../components/deployment_detail.dart';
import '../components/deployment_list.dart';
import '../components/artifact_list.dart';
import '../components/artifact_detail.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';
import '../components/split_view.dart';

class ApiDetailPage extends StatelessWidget {
  final String? name;
  ApiDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      selection.updateApiName(name!.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: DefaultTabController(
        length: 4,
        animationDuration: Duration.zero,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              this.name ?? "API Details",
            ),
            actions: <Widget>[
              homeButton(context),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: "Details"),
                Tab(text: "Versions"),
                Tab(text: "Deployments"),
                Tab(text: "Artifacts"),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    ApiDetailCard(editable: true),
                    CustomSplitView(
                      viewMode: SplitViewMode.Horizontal,
                      initialWeight: 0.33,
                      view1: VersionListCard(),
                      view2: VersionDetailCard(
                        selflink: true,
                        editable: true,
                      ),
                    ),
                    CustomSplitView(
                      viewMode: SplitViewMode.Horizontal,
                      initialWeight: 0.33,
                      view1: DeploymentListCard(),
                      view2: DeploymentDetailCard(
                        selflink: true,
                        editable: true,
                      ),
                    ),
                    CustomSplitView(
                      viewMode: SplitViewMode.Horizontal,
                      view1: ArtifactListCard(SelectionProvider.api),
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
