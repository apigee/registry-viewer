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

class EditPropertyForm extends StatefulWidget {
  @override
  EditPropertyFormState createState() => EditPropertyFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditPropertyFormState extends State<EditPropertyForm> {
  Selection selection;
  PropertyManager propertyManager;

  void listener() {
    setState(() {});
  }

  void nameChangeListener() {
    setState(() {
      setPropertyName(SelectionProvider.of(context).propertyName.value);
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    SelectionProvider.of(context).propertyName.addListener(nameChangeListener);
    super.didChangeDependencies();
    setPropertyName(SelectionProvider.of(context)?.propertyName?.value);
  }

  void setPropertyName(String name) {
    if (propertyManager?.name == name) {
      return;
    }
    // forget the old manager
    propertyManager?.removeListener(listener);
    // get the new manager
    propertyManager = RegistryProvider.of(context).getPropertyManager(name);
    propertyManager.addListener(listener);
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
    selection?.apiName?.removeListener(nameChangeListener);
    propertyManager?.removeListener(listener);
    stringValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (propertyManager?.value == null) {
      print("building while empty");
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final property = propertyManager.value;
      stringValueController.text = property.stringValue;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(property.name),
            ListTile(
              title: TextFormField(
                controller: stringValueController,
              ),
              subtitle: Text("Display Name"),
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
    if (propertyManager?.value != null && _formKey.currentState.validate()) {
      final property = propertyManager.value.clone();
      if (property.stringValue != stringValueController.text) {
        property.stringValue = stringValueController.text;
      }
      propertyManager?.update(property);
    }
  }
}
