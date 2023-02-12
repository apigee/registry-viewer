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
import '../models/artifact.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ArtifactText displays a text artifact.
class ArtifactText extends StatefulWidget {
  final String Function() artifactName;

  const ArtifactText(this.artifactName);
  @override
  ArtifactTextState createState() => ArtifactTextState();
}

class ArtifactTextState extends State<ArtifactText> {
  ArtifactManager? artifactManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setArtifactName(
        widget.artifactName(),
      );
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
    if (artifactManager?.value == null) {
      return Container();
    }

    Artifact artifact = artifactManager!.value!;
    return Text(
      artifact.stringValue,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall!,
    );
  }
}
