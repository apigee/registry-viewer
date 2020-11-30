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
import '../helpers/title.dart';
import '../components/logout_button.dart';
import '../components/version_list.dart';
import '../models/observable.dart';
import '../models/selection.dart';
import '../models/version.dart';

// convert /projects/{project}/apis/{api}/versions
// to projects/{project}/apis/{api}
String parent(String name) {
  var parts = name.split('/');
  return parts.sublist(1, 5).join('/');
}

// VersionListPage is a full-page display of a list of versions.
class VersionListPage extends StatelessWidget {
  final String name;
  final String apiName;
  VersionListPage(String name, {Key key})
      : name = name,
        apiName = parent(name),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionModel = Selection();
    selectionModel.apiName.update(apiName);
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title(name)),
            actions: <Widget>[
              Container(width: 400, child: VersionSearchBox()),
              logoutButton(context),
            ],
          ),
          body: Center(
            child: VersionListView(
              (context, version) {
                Navigator.pushNamed(
                  context,
                  version.routeNameForDetail(),
                  arguments: version,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
