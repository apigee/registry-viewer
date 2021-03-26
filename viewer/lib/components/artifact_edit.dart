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
import 'package:flutter/services.dart';
import 'package:registry/registry.dart';
import '../models/selection.dart';
import '../models/artifact.dart';
import '../service/registry.dart';
import '../helpers/errors.dart';

class EditArtifactForm extends StatefulWidget {
  @override
  EditArtifactFormState createState() => EditArtifactFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditArtifactFormState extends State<EditArtifactForm> {
  Selection selection;
  ArtifactManager artifactManager;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setArtifactName(SelectionProvider.of(context).artifactName.value);
    });
  }

  void setArtifactName(String name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    // get the new manager
    artifactManager = RegistryProvider.of(context).getArtifactManager(name);
    artifactManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.artifactName.addListener(selectionListener);
    super.didChangeDependencies();
    setArtifactName(SelectionProvider.of(context)?.artifactName?.value);
  }

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  // Create controllers for form fields.
  final stringValueController = TextEditingController();

  @override
  void dispose() {
    selection.artifactName?.removeListener(selectionListener);
    artifactManager?.removeListener(managerListener);
    stringValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (artifactManager?.value == null) {
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final artifact = artifactManager.value;
      stringValueController.text = artifact.stringValue;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(artifact.name),
            ListTile(
              title: TextFormField(
                controller: stringValueController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(".*")),
                ],
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              subtitle: Text("value (string)"),
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
    Selection selection = SelectionProvider.of(context);
    if (artifactManager?.value != null && _formKey.currentState.validate()) {
      final artifact = artifactManager.value.clone();
      if (artifact.stringValue != stringValueController.text) {
        artifact.stringValue = stringValueController.text;
      }
      artifactManager
          ?.update(artifact, onError(context))
          ?.then((Artifact artifact) {
        selection.notifySubscribersOf(artifact.subject);
      });
    }
  }
}
