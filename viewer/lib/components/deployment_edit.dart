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
import '../models/selection.dart';
import '../service/registry.dart';
import '../helpers/errors.dart';

class EditDeploymentForm extends StatefulWidget {
  @override
  EditDeploymentFormState createState() => EditDeploymentFormState();
}

// Define a corresponding State class.
// This class holds data related to the form.
class EditDeploymentFormState extends State<EditDeploymentForm> {
  Selection? selection;
  DeploymentManager? deploymentManager;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setDeploymentName(SelectionProvider.of(context)!.versionName.value);
    });
  }

  void setDeploymentName(String name) {
    if (deploymentManager?.name == name) {
      return;
    }
    // forget the old manager
    deploymentManager?.removeListener(managerListener);
    // get the new manager
    deploymentManager =
        RegistryProvider.of(context)!.getDeploymentManager(name);
    deploymentManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.versionName.addListener(selectionListener);
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
    selection?.apiName.removeListener(selectionListener);
    deploymentManager?.removeListener(managerListener);
    displayNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (deploymentManager?.value == null) {
      return const Card();
    } else {
      // Build a Form widget using the _formKey created above.
      final deployment = deploymentManager!.value!;
      displayNameController.text = deployment.displayName;
      descriptionController.text = deployment.description;

      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(deployment.name.split("/").sublist(4).join("/")),
            ListTile(
              title: TextFormField(
                controller: displayNameController,
              ),
              subtitle: const Text("Display Name"),
            ),
            ListTile(
              title: TextFormField(
                controller: descriptionController,
              ),
              subtitle: const Text("Description"),
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
  }

  void save(BuildContext context) {
    if (deploymentManager?.value != null && _formKey.currentState!.validate()) {
      final deployment = deploymentManager!.value!.deepCopy();
      List<String> paths = [];
      if (deployment.displayName != displayNameController.text) {
        deployment.displayName = displayNameController.text;
        paths.add("display_name");
      }
      if (deployment.description != descriptionController.text) {
        deployment.description = descriptionController.text;
        paths.add("description");
      }
      deploymentManager?.update(deployment, paths, onError(context));
    }
  }
}
