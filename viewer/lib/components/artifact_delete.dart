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
import 'package:protobuf/protobuf.dart';
import '../models/artifact.dart';
import '../models/selection.dart';
import '../service/registry.dart';

class DeleteArtifactForm extends StatefulWidget {
  @override
  DeleteArtifactFormState createState() => DeleteArtifactFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class DeleteArtifactFormState extends State<DeleteArtifactForm> {
  Selection? selection;
  ArtifactManager? artifactManager;

  void listener() {
    setState(() {});
  }

  void nameChangeListener() {
    setState(() {
      setArtifactName(SelectionProvider.of(context)!.artifactName.value);
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    SelectionProvider.of(context)!.artifactName.addListener(nameChangeListener);
    super.didChangeDependencies();
    setArtifactName(SelectionProvider.of(context)?.artifactName.value);
  }

  void setArtifactName(String? name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(listener);
    // get the new manager
    artifactManager = RegistryProvider.of(context)!.getArtifactManager(name);
    artifactManager!.addListener(listener);
    // get the value from the manager
    listener();
  }

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final stringValueController = TextEditingController();

  @override
  void dispose() {
    selection?.artifactName.removeListener(nameChangeListener);
    artifactManager?.removeListener(listener);
    stringValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (artifactManager?.value == null) {
      print("building while empty");
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final artifact = artifactManager!.value!;
      stringValueController.text = artifact.relation;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("Delete this artifact?"),
            Text(artifact.name),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  child: Text("No, Cancel"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  child: Text("Yes, Delete it"),
                  onPressed: () {
                    delete(context);
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

  void delete(BuildContext context) {
    Selection? selection = SelectionProvider.of(context);
    if (artifactManager?.value != null && _formKey.currentState!.validate()) {
      final artifact = artifactManager!.value!.deepCopy();
      print("deleting $artifact");
      String subject = artifact.subject;
      artifactManager?.delete(artifact.name).then((x) {
        selection!.notifySubscribersOf(subject);
      });
    }
  }
}
