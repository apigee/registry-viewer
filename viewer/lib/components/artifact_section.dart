// Copyright 2023 Google LLC. All Rights Reserved.
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
import 'package:viewer/components/artifact_fields.dart';
import 'package:viewer/components/artifact_card.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ArtifactSection displays an arbitrary artifact.
class ArtifactSection extends StatefulWidget {
  final String Function() parentName;

  const ArtifactSection(this.parentName, {super.key});
  @override
  ArtifactSectionState createState() => ArtifactSectionState();
}

class ArtifactSectionState extends State<ArtifactSection> {
  ArtifactListManager? artifactListManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setParentName(
        widget.parentName(),
      );
    });
  }

  void setParentName(String name) {
    if (artifactListManager?.name == name) {
      return;
    }
    // forget the old manager
    artifactListManager?.removeListener(managerListener);
    // get the new manager
    artifactListManager =
        RegistryProvider.of(context)!.getArtifactListManager(name);
    artifactListManager!.addListener(managerListener);
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
    artifactListManager?.removeListener(managerListener);
    selection!.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (artifactListManager?.value == null) {
      return Container(color: Colors.red);
    }

    List<Artifact> artifacts = artifactListManager!.value!.artifacts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var a in artifacts)
        if (kind(a.mimeType) == "FieldSet") ArtifactFieldSetCard(() => a.name),
      for (var a in artifacts)
        if (kind(a.mimeType) == "ReferenceList") ArtifactCard(() => a.name),
      for (var a in artifacts)
        if (kind(a.mimeType) == "Summary") ArtifactCard(() => a.name),
      for (var a in artifacts)
        Row(children: [
          Text("${id(a.name)} - ${kind(a.mimeType)}"),
        ]),
      Divider(
        color: Theme.of(context).primaryColor,
      ),
    ]);
  }
}

String id(String path) {
  return path.split("/").last;
}

String kind(String mimeType) {
  return mimeType.split(".").last.split("=").last;
}
