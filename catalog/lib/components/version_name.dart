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
import '../models/version.dart';

class VersionNameCard extends StatefulWidget {
  @override
  _VersionNameCardState createState() => _VersionNameCardState();
}

class _VersionNameCardState extends State<VersionNameCard> {
  VersionManager versionManager;
  void listener() {
    setState(() {});
  }

  void setVersionName(String name) {
    if (versionManager?.name == name) {
      return;
    }
    // forget the old manager
    versionManager?.removeListener(listener);
    versionManager = null;
    // get the new manager
    versionManager = RegistryProvider.of(context).getVersionManager(name);
    versionManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).spec.addListener(() {
      setState(() {
        setVersionName(SelectionProvider.of(context).version.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (versionManager?.value == null) {
      return Card();
    } else {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(versionManager.value.name,
                  style: Theme.of(context).textTheme.headline5),
              subtitle: Text("${versionManager.value}"),
            ),
            ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text('SPECS'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      versionManager.value.routeNameForSpecs(),
                    );
                  },
                ),
                FlatButton(
                  child: const Text('MORE'),
                  onPressed: () {/* ... */},
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
