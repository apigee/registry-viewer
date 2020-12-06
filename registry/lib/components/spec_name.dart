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
import '../components/spec_edit.dart';

class SpecNameCard extends StatefulWidget {
  @override
  _SpecNameCardState createState() => _SpecNameCardState();
}

class _SpecNameCardState extends State<SpecNameCard> {
  SpecManager specManager;
  void listener() {
    setState(() {});
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

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).specName.addListener(() {
      setState(() {
        setSpecName(SelectionProvider.of(context).specName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (specManager?.value == null) {
      return Card();
    } else {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(specManager.value.name,
                  style: Theme.of(context).textTheme.headline5),
            ),
            ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text('EDIT'),
                  onPressed: () {
                    final selection = SelectionProvider.of(context);
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return SelectionProvider(
                            selection: selection,
                            child: AlertDialog(
                              content: EditSpecForm(),
                            ),
                          );
                        });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
