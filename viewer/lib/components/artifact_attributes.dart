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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// ArtifactAttributesCard displays an arbitrary artifact.
class ArtifactAttributesCard extends StatefulWidget {
  final String Function() artifactName;

  const ArtifactAttributesCard(this.artifactName, {super.key});
  @override
  ArtifactAttributesCardState createState() => ArtifactAttributesCardState();
}

class ArtifactAttributesCardState extends State<ArtifactAttributesCard> {
  ArtifactManager? artifactManager;
  ArtifactManager? definitionManager;
  Selection? selection;

  void managerListener() {
    if (artifactManager == null) {
      return;
    }
    if (artifactManager!.value == null) {
      return;
    }
    Artifact artifact = artifactManager!.value!;
    Attributes attributes = Attributes.fromBuffer(artifact.contents);
    setDefinitionName(attributes.definitionName);
    setState(() {});
  }

  void definitionListener() {
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
    setDefinitionName("");
    // forget the old manager
    artifactManager?.removeListener(managerListener);
    if (name == "") {
      return;
    }
    // get the new manager
    artifactManager = RegistryProvider.of(context)!.getArtifactManager(name);
    artifactManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  void setDefinitionName(String name) {
    if (definitionManager?.name == name) {
      return;
    }
    // forget the old manager
    definitionManager?.removeListener(definitionListener);
    if (name == "") {
      return;
    }
    // get the new manager
    definitionManager = RegistryProvider.of(context)!.getArtifactManager(name);
    definitionManager!.addListener(definitionListener);
    // get the value from the manager
    definitionListener();
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
    definitionManager?.removeListener(definitionListener);
    artifactManager?.removeListener(managerListener);
    selection!.artifactName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (artifactManager?.value == null) {
      return Container(color: Colors.red);
    }

    Artifact artifact = artifactManager!.value!;
    debugPrint(artifact.mimeType);
    if (artifact.mimeType !=
        "application/octet-stream;type=google.cloud.apigeeregistry.v1.apihub.Attributes") {
      return Container(color: Colors.purple);
    }

    if (definitionManager?.value == null) {
      return Container(color: Colors.yellow);
    }

    Artifact definitionArtifact = definitionManager!.value!;
    AttributesDefinition definition =
        AttributesDefinition.fromBuffer(definitionArtifact.contents);

    Attributes facet = Attributes.fromBuffer(artifact.contents);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(definition.description,
            style: Theme.of(context).textTheme.titleSmall!),
        Table(children: [
          for (var attribute in definition.attributes)
            if (facet.values[attribute.name] != null)
              TableRow(children: [
                Text(attribute.title),
                MarkdownBody(
                  data: facet.values[attribute.name] ?? "",
                  onTapLink: (text, url, title) {
                    launchUrl(Uri.parse(url!));
                  },
                ),
              ]),
        ]),
        Divider(
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
