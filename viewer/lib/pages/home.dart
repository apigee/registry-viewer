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
import '../application.dart';
import 'package:split_view/split_view.dart';
import '../components/about.dart';
import '../components/project_detail.dart';
import '../components/project_list.dart';
import '../models/selection.dart';
import '../components/bottom_bar.dart';
import '../components/split_view.dart';
import '../components/search.dart';
import '../helpers/media.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();
    return SelectionProvider(
      selection: selection,
      child: DefaultTabController(
        length: 3,
        initialIndex: 0,
        animationDuration: const Duration(milliseconds: 100),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(applicationName),
            bottom: const TabBar(
              tabs: [
                Tab(text: "Projects"),
                Tab(text: "About"),
                Tab(text: "Search"),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    narrow(context)
                        ? const ProjectListCard(
                            singleColumn: true,
                          )
                        : const CustomSplitView(
                            viewMode: SplitViewMode.Horizontal,
                            initialWeight: 0.33,
                            view1: ProjectListCard(
                              singleColumn: false,
                            ),
                            view2: ProjectDetailCard(
                                selflink: true, editable: true),
                          ),
                    const AboutCard(),
                    const SearchCard(),
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
