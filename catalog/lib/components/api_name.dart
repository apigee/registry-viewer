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
import '../models/api.dart';
import '../components/api_edit.dart';

class ApiNameCard extends StatefulWidget {
  @override
  _ApiNameCardState createState() => _ApiNameCardState();
}

class _ApiNameCardState extends State<ApiNameCard> {
  ApiManager apiManager;
  void listener() {
    setState(() {});
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(listener);
    // get the new manager
    apiManager = RegistryProvider.of(context).getApiManager(name);
    apiManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).apiName.addListener(() {
      setState(() {
        setApiName(SelectionProvider.of(context).apiName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (apiManager?.value == null) {
      return Card();
    } else {
      return Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(apiManager.value.name,
                  style: Theme.of(context).textTheme.headline5),
              subtitle: Text("${apiManager.value}"),
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
                              content: EditAPIForm(),
                            ),
                          );
                        });
                  },
                ),
                FlatButton(
                  child: const Text('VERSIONS'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      apiManager.value.routeNameForVersions(),
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
