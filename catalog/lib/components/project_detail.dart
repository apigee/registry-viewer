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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/selection.dart';
import '../models/project.dart';
import 'info.dart';

// ProjectDetailCard is a card that displays details about a project.
class ProjectDetailCard extends StatefulWidget {
  _ProjectDetailCardState createState() => _ProjectDetailCardState();
}

class _ProjectDetailCardState extends State<ProjectDetailCard> {
  String projectName = "";
  Project project;

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).project.addListener(() => setState(() {
          projectName = SelectionProvider.of(context).project.value;
          if (projectName == null) {
            projectName = "";
          }
          this.project = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      if (projectName != "") {
        // we need to fetch the project from the API
        ProjectService().getProject(projectName).then((project) {
          setState(() {
            this.project = project;
          });
        });
      }
      return Card();
    } else {
      return Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ProjectInfoWidget(project),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ProjectInfoWidget extends StatelessWidget {
  final Project project;
  ProjectInfoWidget(this.project);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResourceNameButtonRow(
          name: project.name,
          show: () {
            Navigator.pushNamed(
              context,
              project.routeNameForDetail(),
              arguments: project,
            );
          },
        ),
        SizedBox(height: 10),
        TitleRow(project.displayName),
        SizedBox(height: 10),
        BodyRow(project.description),
        SizedBox(height: 10),
        TimestampRow("created", project.createTime),
        TimestampRow("updated", project.updateTime),
      ],
    );
  }
}
