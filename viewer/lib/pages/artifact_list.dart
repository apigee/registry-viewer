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
import '../components/artifact_list.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';
import '../models/string.dart';
import '../models/selection.dart';

// ArtifactListPage is a full-page display of a list of artifacts.
class ArtifactListPage extends StatefulWidget {
  final String? name;

  const ArtifactListPage(String? name, {Key? key})
      : name = name,
        super(key: key);
  @override
  _ArtifactListPageState createState() => _ArtifactListPageState();
}

class _ArtifactListPageState extends State<ArtifactListPage> {
  // convert /projects/{project}/locations/global/artifacts to projects/{project}/locations/global
  String parentName() {
    List parts = widget.name!.split("/");
    parts.insert(3, "global");
    parts.insert(3, "locations");
    String name2 = parts.join("/");
    List parts2 = name2.split("/");
    String parent = parts2.sublist(1, parts2.length - 1).join('/');
    return parent;
  }

  @override
  Widget build(BuildContext context) {
    // what is the parent type? Use that to determine the string to observe for the list view
    ObservableString Function(BuildContext) parent;
    final selectionModel = Selection();
    String name = parentName();
    if (name.contains("/deployments/")) {
      parent = SelectionProvider.deployment;
      selectionModel.deploymentName.update(name);
    } else if (name.contains("/specs/")) {
      parent = SelectionProvider.spec;
      selectionModel.specName.update(name);
    } else if (name.contains("/versions/")) {
      parent = SelectionProvider.version;
      selectionModel.versionName.update(name);
    } else if (name.contains("/apis/")) {
      parent = SelectionProvider.api;
      selectionModel.apiName.update(name);
    } else {
      parent = SelectionProvider.project;
      selectionModel.projectName.update(name);
    }
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(title(widget.name!)),
            actions: <Widget>[
              homeButton(context),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ArtifactListCard(
                  parent,
                  singleColumn: true,
                ),
              ),
              BottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
