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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../models/selection.dart';
import '../models/project.dart';
import 'detail_rows.dart';
import '../service/registry.dart';
import '../components/project_edit.dart';

// ProjectDetailCard is a card that displays details about a project.
class ProjectDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  ProjectDetailCard({this.selflink, this.editable});
  _ProjectDetailCardState createState() => _ProjectDetailCardState();
}

class _ProjectDetailCardState extends State<ProjectDetailCard> {
  ProjectManager projectManager;
  void listener() {
    setState(() {});
  }

  void setProjectName(String name) {
    if (projectManager?.name == name) {
      return;
    }
    // forget the old manager
    projectManager?.removeListener(listener);
    // get the new manager
    projectManager = RegistryProvider.of(context).getProjectManager(name);
    projectManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).projectName.addListener(() {
      setState(() {
        setProjectName(SelectionProvider.of(context).projectName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Project project = projectManager?.value;
      Navigator.pushNamed(
        context,
        project.routeNameForDetail(),
        arguments: project,
      );
    });

    Function editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: EditProjectForm(),
              ),
            );
          });
    });

    if (projectManager?.value == null) {
      return Card();
    } else {
      Project project = projectManager.value;
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResourceNameButtonRow(
                name: project.name, show: selflink, edit: editable),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      TitleRow(project.displayName, action: selflink),
                      SizedBox(height: 10),
                      BodyRow(project.description),
                      SizedBox(height: 10),
                      TimestampRow("created", project.createTime),
                      TimestampRow("updated", project.updateTime),
                      DetailRow(""),
                      DetailRow("$project"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
