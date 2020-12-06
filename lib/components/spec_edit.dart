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

class EditSpecForm extends StatefulWidget {
  @override
  EditSpecFormState createState() => EditSpecFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditSpecFormState extends State<EditSpecForm> {
  Selection selection;
  SpecManager specManager;

  void listener() {
    setState(() {});
  }

  void nameChangeListener() {
    setState(() {
      setSpecName(SelectionProvider.of(context).specName.value);
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    SelectionProvider.of(context).specName.addListener(nameChangeListener);
    super.didChangeDependencies();
    setSpecName(SelectionProvider.of(context)?.specName?.value);
  }

  void setSpecName(String name) {
    if (specManager?.name == name) {
      return;
    }
    // forget the old manager
    specManager?.removeListener(listener);
    // get the new manager
    specManager = RegistryProvider.of(context).getSpecManager(name);
    specManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    selection?.apiName?.removeListener(nameChangeListener);
    specManager?.removeListener(listener);
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (specManager?.value == null) {
      print("building while empty");
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final spec = specManager.value;
      descriptionController.text = spec.description;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(spec.name),
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
    if (specManager?.value != null && _formKey.currentState.validate()) {
      final spec = specManager.value.clone();
      List<String> paths = List();
      if (spec.description != descriptionController.text) {
        spec.description = descriptionController.text;
        paths.add("description");
      }
      specManager?.update(spec, paths);
    }
  }
}
