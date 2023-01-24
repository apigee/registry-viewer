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
import 'package:registry/registry.dart';
import 'detail_rows.dart';
import 'artifact_detail_complexity.dart';
import 'artifact_detail_message.dart';
import 'artifact_detail_lint.dart';
import 'artifact_detail_lintstats.dart';
import 'artifact_detail_references.dart';
import 'artifact_detail_string.dart';
import 'artifact_detail_vocabulary.dart';
import '../helpers/extensions.dart';
import '../models/artifact.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ArtifactDetailCard is a card that displays details about an artifact.
class ArtifactDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  ArtifactDetailCard({this.selflink, this.editable});
  _ArtifactDetailCardState createState() => _ArtifactDetailCardState();
}

class _ArtifactDetailCardState extends State<ArtifactDetailCard> {
  ArtifactManager? artifactManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context)!.artifactName.value);
    });
  }

  void setProjectName(String name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    // get the new manager
    artifactManager = RegistryProvider.of(context)!.getArtifactManager(name);
    artifactManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.artifactName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    artifactManager?.removeListener(managerListener);
    selection!.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function? selflink = onlyIf(widget.selflink, () {
      Artifact artifact = (artifactManager?.value)!;
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
      Artifact artifact = artifactManager!.value!;
      if (artifact.mimeType.startsWith("application/yaml") ||
          artifact.mimeType.startsWith("application/json")) {
        return StringArtifactCard(artifact,
            selflink: selflink, editable: false);
      }
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
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.ApiSpecExtensionList":
          return MessageArtifactCard(
              artifact, new ApiSpecExtensionList.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.DisplaySettings":
          return MessageArtifactCard(
              artifact, new DisplaySettings.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.Lifecycle":
          return MessageArtifactCard(
              artifact, new Lifecycle.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.ReferenceList":
          return MessageArtifactCard(
              artifact, new ReferenceList.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.TaxonomyList":
          return MessageArtifactCard(
              artifact, new TaxonomyList.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.controller.Manifest":
          return MessageArtifactCard(
              artifact, new Manifest.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.controller.Receipt":
          return MessageArtifactCard(
              artifact, new Receipt.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.scoring.Score":
          return MessageArtifactCard(
              artifact, new Score.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.scoring.ScoreCard":
          return MessageArtifactCard(
              artifact, new ScoreCard.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.scoring.ScoreCardDefinition":
          return MessageArtifactCard(
              artifact, new ScoreCardDefinition.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.scoring.ScoreDefinition":
          return MessageArtifactCard(
              artifact, new ScoreDefinition.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.style.ConformanceReport":
          return MessageArtifactCard(
              artifact, new ConformanceReport.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.style.StyleGuide":
          return MessageArtifactCard(
              artifact, new StyleGuide.fromBuffer(artifact.contents),
              selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.style.Lint":
          return LintArtifactCard(artifact, selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.style.LintStats":
          return LintStatsArtifactCard(artifact, selflink: selflink);
        case "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.References":
          return ReferencesArtifactCard(artifact, selflink: selflink);
      }

      // otherwise return a default display of the artifact
      return DefaultArtifactDetailCard(selflink: selflink);
    }
  }
}

// DefaultArtifactDetailCard is a card that displays details about an artifact.
class DefaultArtifactDetailCard extends StatefulWidget {
  final Function? selflink;
  DefaultArtifactDetailCard({this.selflink});
  _DefaultArtifactDetailCardState createState() =>
      _DefaultArtifactDetailCardState();
}

class _DefaultArtifactDetailCardState extends State<DefaultArtifactDetailCard> {
  ArtifactManager? artifactManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setArtifactName(SelectionProvider.of(context)!.artifactName.value);
    });
  }

  void setArtifactName(String name) {
    if (artifactManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    // get the new manager
    artifactManager = RegistryProvider.of(context)!.getArtifactManager(name);
    artifactManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.artifactName.addListener(selectionListener);
    selectionListener();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    artifactManager?.removeListener(managerListener);
    selection!.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Artifact? artifact = artifactManager?.value;
    if (artifact == null) {
      return Card(child: Text("$artifactManager"));
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
              name: artifact.name.last(1),
              show: widget.selflink as void Function()?,
              edit: null),
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
