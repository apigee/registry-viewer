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
import '../helpers/media.dart';
import '../helpers/title.dart';

class ApiDetailPage extends StatelessWidget {
  final String? name;
  const ApiDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      String name2 = name!.replaceAll("/apis/", "/locations/global/apis/");
      selection.updateApiName(name2.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: DefaultTabController(
        length: 4,
        initialIndex: 1,
        animationDuration: Duration(milliseconds: 100),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(pageTitle(name) ?? "API Details"),
            actions: <Widget>[
              homeButton(context),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Text(
                    "Details",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
                Tab(
                  child: Text(
                    "Versions",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
                Tab(
                  child: Text(
                    "Deployments",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
                Tab(
                  child: Text(
                    "Artifacts",
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
              ],
              //  indicator: tabDecoration(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    ApiDetailCard(editable: true),
                    narrow(context)
                        ? VersionListCard(
                            singleColumn: true,
                          )
                        : CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            initialWeight: 0.33,
                            view1: VersionListCard(singleColumn: false),
                            view2: VersionDetailCard(
                              selflink: true,
                              editable: true,
                            ),
                          ),
                    narrow(context)
                        ? DeploymentListCard(
                            singleColumn: true,
                          )
                        : CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            initialWeight: 0.33,
                            view1: DeploymentListCard(
                              singleColumn: false,
                            ),
                            view2: DeploymentDetailCard(
                              selflink: true,
                              editable: true,
                            ),
                          ),
                    narrow(context)
                        ? ArtifactListCard(
                            SelectionProvider.api,
                            singleColumn: true,
                          )
                        : CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            view1: ArtifactListCard(
                              SelectionProvider.api,
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
              BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
