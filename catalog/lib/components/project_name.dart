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
import '../models/selection.dart';
import '../service/registry.dart';
import '../models/project.dart';
import '../components/project_edit.dart';

class ProjectNameCard extends StatefulWidget {
  @override
  _ProjectNameCardState createState() => _ProjectNameCardState();
}

class _ProjectNameCardState extends State<ProjectNameCard> {
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
    if (projectManager?.value == null) {
      return Card();
    } else {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(projectManager.value.name,
                  style: Theme.of(context).textTheme.headline5),
              subtitle: Text("${projectManager.value}"),
            ),
            ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text('EDIT'),
                  onPressed: () {
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
                  },
                ),
                FlatButton(
                  child: const Text('VERSIONS'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      projectManager.value.routeNameForApis(),
                    );
                  },
                ),
                FlatButton(
                  child: const Text('MORE'),
                  onPressed: () {/* ... */},
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
