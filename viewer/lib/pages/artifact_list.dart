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
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/registry.dart';
import '../helpers/title.dart';
import '../components/artifact_list.dart';
import '../components/home_button.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../models/artifact.dart';
import '../service/service.dart';

// ArtifactListPage is a full-page display of a list of artifacts.
class ArtifactListPage extends StatefulWidget {
  final String name;

  ArtifactListPage(String name, {Key key})
      : name = name,
        super(key: key);
  @override
  _ArtifactListPageState createState() => _ArtifactListPageState();
}

class _ArtifactListPageState extends State<ArtifactListPage> {
  ArtifactService artifactService;
  PagewiseLoadController<Artifact> pageLoadController;

  _ArtifactListPageState() {
    artifactService = ArtifactService();
    pageLoadController = PagewiseLoadController<Artifact>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => artifactService.getArtifactsPage(pageIndex));
  }

  // convert /projects/{project}/artifacts to projects/{project}
  String parentName() {
    return widget.name.split('/').sublist(1, 3).join('/');
  }

  @override
  Widget build(BuildContext context) {
    final selectionModel = Selection();
    selectionModel.projectName.update(parentName());
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title(widget.name)),
            actions: <Widget>[
              Container(width: 400, child: ArtifactSearchBox()),
              homeButton(context),
            ],
          ),
          body: Center(
            child: ArtifactListView(
              null,
              (context, artifact) {
                Navigator.pushNamed(
                  context,
                  artifact.routeNameForDetail(),
                  arguments: artifact,
                );
              },
              artifactService,
              pageLoadController,
            ),
          ),
        ),
      ),
    );
  }
}
