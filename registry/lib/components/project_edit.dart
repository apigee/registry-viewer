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

class EditProjectForm extends StatefulWidget {
  @override
  EditProjectFormState createState() => EditProjectFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditProjectFormState extends State<EditProjectForm> {
  ProjectManager projectManager;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context).projectName.value);
    });
  }

  void setProjectName(String name) {
    if (projectManager?.name == name) {
      return;
    }
    // forget the old manager
    projectManager?.removeListener(managerListener);
    // get the new manager
    projectManager = RegistryProvider.of(context).getProjectManager(name);
    projectManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).projectName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  // Create controllers for form fields.
  final displayNameController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    SelectionProvider.of(context)
        .projectName
        ?.removeListener(selectionListener);
    projectManager?.removeListener(managerListener);
    displayNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (projectManager?.value == null) {
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final project = projectManager.value;
      displayNameController.text = project.displayName;
      descriptionController.text = project.description;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(project.name),
            ListTile(
              title: TextFormField(
                controller: displayNameController,
              ),
              subtitle: Text("Display Name"),
            ),
            ListTile(
              title: TextFormField(
                controller: descriptionController,
              ),
              subtitle: Text("Description"),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  child: Text("Save"),
                  onPressed: () {
                    save(context);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              )
            ]),
          ],
        ),
      );
    }
  }

  void save(BuildContext context) {
    if (projectManager?.value != null && _formKey.currentState.validate()) {
      final project = projectManager.value.clone();
      List<String> paths = [];
      if (project.displayName != displayNameController.text) {
        project.displayName = displayNameController.text;
        paths.add("display_name");
      }
      if (project.description != descriptionController.text) {
        project.description = descriptionController.text;
        paths.add("description");
      }
      projectManager?.update(project, paths);
    }
  }
}
