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
import '../helpers/title.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';
import '../components/project_list.dart';
import '../models/string.dart';

// ProjectListPage is a full-page display of a list of projects.
class ProjectListPage extends StatefulWidget {
  final String? name;

  ProjectListPage(String? name, {Key? key})
      : name = name,
        super(key: key);
  @override
  _ProjectListPageState createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(title(widget.name!)),
          actions: <Widget>[
            homeButton(context),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ProjectListCard(singleColumn: true),
            ),
            BottomBar(),
          ],
        ),
      ),
    );
  }
}
