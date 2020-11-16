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
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/project.dart';
import '../models/selection.dart';

const int pageSize = 50;

// ProjectListCard is a card that displays a list of projects.
class ProjectListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var projectList = ProjectList(ProjectService());
    return Card(
      child: Column(
        children: [
          ProjectSearchBox(projectList),
          Expanded(child: projectList),
        ],
      ),
    );
  }
}

// ProjectList contains a ListView of projects.
class ProjectList extends StatelessWidget {
  final PagewiseLoadController<Project> pageLoadController;
  final ProjectService projectService;

  ProjectList(ProjectService projectService)
      : projectService = projectService,
        pageLoadController = PagewiseLoadController<Project>(
            pageSize: pageSize,
            pageFuture: (pageIndex) =>
                projectService.getProjectsPage(pageIndex));

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: PagewiseListView<Project>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Project project, _) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          SelectionModel model = ModelProvider.of(context);
          if (model != null) {
            print("tapped for project ${project.name}");
            model.updateProject(project.name);
          } else {
            Navigator.pushNamed(
              context,
              project.routeNameForDetail(),
              arguments: project,
            );
          }
        },
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ListTile(
                title: Text(project.nameForDisplay()),
                subtitle: Text(project.description),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ProjectSearchBox provides a search box for projects.
class ProjectSearchBox extends StatelessWidget {
  final ProjectList projectList;
  ProjectSearchBox(this.projectList);
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 80, minWidth: 200, maxWidth: 300),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          8,
        ),
        alignment: Alignment.centerLeft,
        color: Colors.white,
        child: TextField(
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.black),
              border: InputBorder.none,
              hintText: 'Filter Projects'),
          onSubmitted: (s) {
            if (s == "") {
              projectList.projectService.filter = "";
            } else {
              projectList.projectService.filter = "project_id.contains('$s')";
            }
            projectList.pageLoadController.reset();
          },
        ),
      ),
    );
  }
}
