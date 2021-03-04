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
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_models.pb.dart';
import 'detail_rows.dart';
import 'artifact_detail_complexity.dart';
import 'artifact_detail_lint.dart';
import 'artifact_detail_lintstats.dart';
import 'artifact_detail_string.dart';
import 'artifact_detail_vocabulary.dart';
import '../helpers/extensions.dart';
import '../models/artifact.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ArtifactDetailCard is a card that displays details about an artifact.
class ArtifactDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  ArtifactDetailCard({this.selflink, this.editable});
  _ArtifactDetailCardState createState() => _ArtifactDetailCardState();
}

class _ArtifactDetailCardState extends State<ArtifactDetailCard> {
  ArtifactManager artifactManager;
  Selection selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context).artifactName.value);
    });
  }

  void setProjectName(String name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    // get the new manager
    artifactManager = RegistryProvider.of(context).getArtifactManager(name);
    artifactManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.artifactName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    artifactManager?.removeListener(managerListener);
    selection.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Artifact artifact = artifactManager?.value;
      Navigator.pushNamed(
        context,
        artifact.routeNameForDetail(),
      );
    });

    if (artifactManager?.value == null) {
      return Card(
        child: Container(
          color: Theme.of(context).canvasColor,
        ),
      );
    } else {
      Artifact artifact = artifactManager.value;

      switch (artifact.mimeType) {
        case "text/plain":
          return StringArtifactCard(
            artifact,
            selflink: selflink,
            editable: widget.editable,
          );
        case "application/octet-stream;type=gnostic.metrics.Complexity":
          return ComplexityArtifactCard(artifact, selflink: selflink);
        case "application/octet-stream;type=gnostic.metrics.Vocabulary":
          return VocabularyArtifactCard(artifact, selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigee.registry.applications.v1alpha1.Lint":
          return LintArtifactCard(artifact, selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigee.registry.applications.v1alpha1.LintStats":
          return LintStatsArtifactCard(artifact, selflink: selflink);
      }

      // otherwise return a default display of the artifact
      return DefaultArtifactDetailCard(selflink: selflink);
    }
  }
}

// DefaultArtifactDetailCard is a card that displays details about an artifact.
class DefaultArtifactDetailCard extends StatefulWidget {
  final Function selflink;
  DefaultArtifactDetailCard({this.selflink});
  _DefaultArtifactDetailCardState createState() =>
      _DefaultArtifactDetailCardState();
}

class _DefaultArtifactDetailCardState extends State<DefaultArtifactDetailCard> {
  ArtifactManager artifactManager;
  Selection selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setArtifactName(SelectionProvider.of(context).artifactName.value);
    });
  }

  void setArtifactName(String name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    // get the new manager
    artifactManager = RegistryProvider.of(context).getArtifactManager(name);
    artifactManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.artifactName.addListener(selectionListener);
    selectionListener();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    artifactManager?.removeListener(managerListener);
    selection.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Artifact artifact = artifactManager?.value;
    if (artifact == null) {
      return Card(child: Text("$artifactManager"));
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
              name: artifact.name.last(1), show: widget.selflink, edit: null),
          Expanded(
            child: Scrollbar(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      TimestampRow(artifact.createTime, artifact.updateTime),
                      DetailRow("$artifact"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
