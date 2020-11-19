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
import 'custom_search_box.dart';

const int pageSize = 50;

typedef ProjectSelectionHandler = Function(
    BuildContext context, Project project);

// ProjectListCard is a card that displays a list of projects.
class ProjectListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            ProjectSearchBox(),
            Expanded(child: ProjectList(null)),
          ],
        ),
      ),
    );
  }
}

// ProjectList contains a ListView of projects.
class ProjectList extends StatefulWidget {
  final ProjectSelectionHandler selectionHandler;
  ProjectList(this.selectionHandler);
  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  PagewiseLoadController<Project> pageLoadController;
  ProjectService projectService;
  int selectedIndex = -1;

  _ProjectListState() {
    projectService = ProjectService();
    pageLoadController = PagewiseLoadController<Project>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => projectService.getProjectsPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    ObservableStringProvider.of(context).addListener(() => setState(() {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            projectService.filter = filter.value;
            pageLoadController.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: PagewiseListView<Project>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Project project, index) {
    if (index == 0) {
      Future.delayed(const Duration(milliseconds: 0), () {
        SelectionModel model = SelectionProvider.of(context);
        if ((model != null) &&
            ((model.project.value == null) || (model.project.value == ""))) {
          model.updateProject(project.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
        title: Text(project.nameForDisplay()),
        subtitle: Text(project.description),
        selected: index == selectedIndex,
        onTap: () async {
          setState(() {
            selectedIndex = index;
          });
          SelectionModel model = SelectionProvider.of(context);
          if (model != null) {
            model.updateProject(project.name);
          }
          if (widget.selectionHandler != null) {
            widget.selectionHandler(context, project);
          }
        });
  }
}

// ProjectSearchBox provides a search box for projects.
class ProjectSearchBox extends CustomSearchBox {
  ProjectSearchBox() : super("Filter Projects", "project_id.contains('TEXT')");
}
