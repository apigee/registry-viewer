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

class EditAPIForm extends StatefulWidget {
  @override
  EditAPIFormState createState() => EditAPIFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditAPIFormState extends State<EditAPIForm> {
  Selection selection;
  ApiManager apiManager;

  void listener() {
    setState(() {});
  }

  void nameChangeListener() {
    setState(() {
      setApiName(SelectionProvider.of(context).api.value);
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    SelectionProvider.of(context).api.addListener(nameChangeListener);
    super.didChangeDependencies();
    setApiName(SelectionProvider.of(context)?.api?.value);
  }

  void setApiName(String name) {
    print("setting API to name $name");
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(listener);
    apiManager = null;
    // get the new manager
    apiManager = RegistryProvider.of(context).getApiManager(name);
    apiManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final displayNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final ownerController = TextEditingController();

  @override
  void dispose() {
    selection?.api?.removeListener(nameChangeListener);
    apiManager?.removeListener(listener);
    displayNameController.dispose();
    descriptionController.dispose();
    ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (apiManager?.value == null) {
      print("building while empty");
      return Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final api = apiManager.value;
      displayNameController.text = api.displayName;
      descriptionController.text = api.description;
      ownerController.text = api.owner;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(api.name.split("/").sublist(2).join("/")),
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
                controller: ownerController,
              ),
              subtitle: Text("Owner"),
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
    if (apiManager?.value != null && _formKey.currentState.validate()) {
      final api = apiManager.value.clone();
      List<String> paths = List();
      if (api.displayName != displayNameController.text) {
        api.displayName = displayNameController.text;
        paths.add("display_name");
      }
      if (api.description != descriptionController.text) {
        api.description = descriptionController.text;
        paths.add("description");
      }
      if (api.owner != ownerController.text) {
        api.owner = ownerController.text;
        paths.add("owner");
      }
      apiManager?.update(api, paths);
    }
  }
}
