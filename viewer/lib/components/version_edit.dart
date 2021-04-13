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
import '../helpers/errors.dart';

class EditVersionForm extends StatefulWidget {
  @override
  EditVersionFormState createState() => EditVersionFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditVersionFormState extends State<EditVersionForm> {
  Selection selection;
  VersionManager versionManager;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setVersionName(SelectionProvider.of(context).versionName.value);
    });
  }

  void setVersionName(String name) {
    if (versionManager?.name == name) {
      return;
    }
    // forget the old manager
    versionManager?.removeListener(managerListener);
    // get the new manager
    versionManager = RegistryProvider.of(context).getVersionManager(name);
    versionManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.versionName.addListener(selectionListener);
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
  final stateController = TextEditingController();

  @override
  void dispose() {
    selection.apiName?.removeListener(selectionListener);
    versionManager?.removeListener(managerListener);
    displayNameController.dispose();
    descriptionController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (versionManager?.value == null) {
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final version = versionManager.value;
      displayNameController.text = version.displayName;
      descriptionController.text = version.description;
      stateController.text = version.state;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(version.name),
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
            ListTile(
              title: TextFormField(
                controller: stateController,
              ),
              subtitle: Text("State"),
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
    if (versionManager?.value != null && _formKey.currentState.validate()) {
      final version = versionManager.value.clone();
      List<String> paths = [];
      if (version.displayName != displayNameController.text) {
        version.displayName = displayNameController.text;
        paths.add("display_name");
      }
      if (version.description != descriptionController.text) {
        version.description = descriptionController.text;
        paths.add("description");
      }
      if (version.state != stateController.text) {
        version.state = stateController.text;
        paths.add("state");
      }
      versionManager?.update(version, paths, onError(context));
    }
  }
}
