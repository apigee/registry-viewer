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
import '../components/home_button.dart';
import '../components/project_list.dart';
import '../models/string.dart';
import '../models/project.dart';
import '../service/service.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';

ProjectService projectService;
PagewiseLoadController<Project> pageLoadController;
final pageSize = 50;

// ProjectListPage is a full-page display of a list of projects.
class ProjectListPage extends StatelessWidget {
  final String name;

  ProjectListPage(String name, {Key key})
      : name = name,
        super(key: key) {
    projectService = ProjectService();
    pageLoadController = PagewiseLoadController<Project>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => projectService.getProjectsPage(pageIndex));
  }

  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title(name)),
          actions: <Widget>[
            Container(width: 400, child: ProjectSearchBox()),
            homeButton(context),
          ],
        ),
        body: Center(
          child: ProjectListView(
            (context, project) {
              Navigator.pushNamed(
                context,
                project.routeNameForDetail(),
                arguments: project,
              );
            },
            projectService,
            pageLoadController,
          ),
        ),
      ),
    );
  }
}
