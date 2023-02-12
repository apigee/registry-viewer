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
import '../service/service.dart';
import '../models/artifact.dart';
import '../models/selection.dart';

class AddArtifactForm extends StatefulWidget {
  final subjectName;
  const AddArtifactForm(this.subjectName);
  @override
  AddArtifactFormState createState() => AddArtifactFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class AddArtifactFormState extends State<AddArtifactForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final stringValueController = TextEditingController();

  @override
  void dispose() {
    stringValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    stringValueController.text = "";

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text("Add an Artifact"),
          ListTile(
            title: TextFormField(
              controller: stringValueController,
            ),
            subtitle: const Text("artifact name"),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: const Text("Save"),
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

  void save(BuildContext context) {
    Selection? selection = SelectionProvider.of(context);
    if (_formKey.currentState!.validate()) {
      String relation = stringValueController.text;
      print("saving relation $relation");
      Artifact artifact = Artifact();
      artifact.name = widget.subjectName + "/artifacts/" + relation;
      artifact.mimeType = "text/plain";
      print("artifact ${artifact.name}");
      if (relation != "") {
        ArtifactService().create(artifact)!.then((Artifact artifact) {
          selection!.notifySubscribersOf(artifact.subject);
        });
      }
    }
  }
}
