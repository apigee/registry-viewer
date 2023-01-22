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
import 'package:registry/registry.dart';
import '../components/detail_rows.dart';
import '../components/dialog_builder.dart';
import '../components/project_edit.dart';
import '../components/empty.dart';
import '../models/project.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ProjectDetailCard is a card that displays details about a project.
class ProjectDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  ProjectDetailCard({this.selflink, this.editable});
  _ProjectDetailCardState createState() => _ProjectDetailCardState();
}

class _ProjectDetailCardState extends State<ProjectDetailCard> {
  ProjectManager? projectManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context)!.projectName.value);
    });
  }

  void setProjectName(String name) {
    if (projectManager?.name == name) {
      return;
    }
    // forget the old manager
    projectManager?.removeListener(managerListener);
    // get the new manager
    projectManager = RegistryProvider.of(context)!.getProjectManager(name);
    projectManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.projectName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    projectManager?.removeListener(managerListener);
    selection!.projectName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (projectManager?.value == null) {
      return emptyCard(context, "project");
    }

    Function? selflink = onlyIf(widget.selflink, () {
      Project project = (projectManager?.value)!;
      Navigator.pushNamed(
        context,
        project.routeNameForDetail(),
      );
    });

    Function? editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: AlertDialog(
                content: DialogBuilder(
                  child: EditProjectForm(),
                ),
              ),
            );
          });
    });

    Project project = projectManager!.value!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: project.name,
            show: selflink as void Function()?,
            edit: editable as void Function()?,
          ),
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
                    TimestampRow(project.createTime, project.updateTime),
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
