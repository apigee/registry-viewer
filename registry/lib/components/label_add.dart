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
import '../service/service.dart';
import '../models/selection.dart';

class AddLabelForm extends StatefulWidget {
  final subjectName;
  AddLabelForm(this.subjectName);
  @override
  AddLabelFormState createState() => AddLabelFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class AddLabelFormState extends State<AddLabelForm> {
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
          Text("Add a Label"),
          ListTile(
            title: TextFormField(
              controller: stringValueController,
            ),
            subtitle: Text("label name"),
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

  void save(BuildContext context) {
    Selection selection = SelectionProvider.of(context);
    if (_formKey.currentState.validate()) {
      Label label = Label();
      label.subject = widget.subjectName;
      label.label = stringValueController.text;
      if (label.label != "") {
        LabelService().create(label).then((Label label) {
          selection.notifySubscribersOf(label.subject);
        });
      }
    }
  }
}
