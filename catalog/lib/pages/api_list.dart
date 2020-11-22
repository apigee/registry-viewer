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
import '../components/api_list.dart';
import '../components/logout.dart';
import '../models/selection.dart';
import '../models/api.dart';

// convert /projects/{project}/apis to projects/{project}
String parent(String name) {
  var parts = name.split('/');
  return parts.sublist(1, 3).join('/');
}

// ApiListPage is a full-page display of a list of apis.
class ApiListPage extends StatelessWidget {
  final String name;
  final String projectName;
  ApiListPage(String name, {Key key})
      : name = name,
        projectName = parent(name),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectionModel = Selection();
    selectionModel.project.update(projectName);
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title(name)),
            actions: <Widget>[
              Container(width: 400, child: ApiSearchBox()),
              logoutButton(context),
            ],
          ),
          body: Center(child: ApiListView((context, api) {
            Navigator.pushNamed(
              context,
              api.routeNameForDetail(),
              arguments: api,
            );
          })),
        ),
      ),
    );
  }
}
