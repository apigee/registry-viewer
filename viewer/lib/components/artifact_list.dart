// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Artifact 2.0 (the "License");
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
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/registry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'custom_search_box.dart';
import 'filter.dart';
import 'artifact_add.dart';
import 'artifact_delete.dart';
import '../models/artifact.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../service/service.dart';

typedef ObservableStringFn = ObservableString Function(BuildContext context);

typedef ArtifactSelectionHandler = Function(
    BuildContext context, Artifact artifact);

// ArtifactListCard is a card that displays a list of artifacts.
class ArtifactListCard extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  ArtifactListCard(this.getObservableResourceName);

  @override
  _ArtifactListCardState createState() => _ArtifactListCardState();
}

class _ArtifactListCardState extends State<ArtifactListCard> {
  ObservableString observableSubjectName;
  String subjectName;
  ArtifactService artifactService;
  PagewiseLoadController<Artifact> pageLoadController;

  _ArtifactListCardState() {
    artifactService = ArtifactService();
    pageLoadController = PagewiseLoadController<Artifact>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => artifactService.getArtifactsPage(pageIndex));
  }

  void selectionListener() {
    pageLoadController?.reset();
    setState(() {
      subjectName = observableSubjectName.value;
      if (subjectName == null) {
        subjectName = "";
      }
    });
  }

  @override
  void didChangeDependencies() {
    observableSubjectName = widget.getObservableResourceName(context);
    observableSubjectName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    observableSubjectName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function add = () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: AddArtifactForm(subjectName),
              ),
            );
          });
    };
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, ArtifactSearchBox(),
                type: "artifacts",
                add: add,
                refresh: () => pageLoadController.reset()),
            Expanded(
              child: ArtifactListView(
                widget.getObservableResourceName,
                null,
                artifactService,
                pageLoadController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ArtifactListView is a scrollable ListView of artifacts.
class ArtifactListView extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  final ArtifactSelectionHandler selectionHandler;
  final ArtifactService artifactService;
  final PagewiseLoadController<Artifact> pageLoadController;
  ArtifactListView(
    this.getObservableResourceName,
    this.selectionHandler,
    this.artifactService,
    this.pageLoadController,
  );
  @override
  _ArtifactListViewState createState() => _ArtifactListViewState();
}

class _ArtifactListViewState extends State<ArtifactListView> {
  String parentName;
  int selectedIndex = -1;
  ObservableString filter;

  void filterListener() {
    setState(() {
      ObservableString filter = ObservableStringProvider.of(context);
      if (filter != null) {
        widget.artifactService.filter = filter.value;
        widget.pageLoadController.reset();
        selectedIndex = -1;
      }
    });
  }

  @override
  void didChangeDependencies() {
    filter = ObservableStringProvider.of(context);
    filter.addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    filter.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.artifactService.context = context;
    String subjectName = widget.getObservableResourceName(context).value;
    if (widget.artifactService.parentName != subjectName) {
      widget.artifactService.parentName = subjectName;
      widget.pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Artifact>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
      ),
    );
  }

  Widget widgetForArtifactValue(Artifact artifact) {
    if (artifact.mimeType == "text/plain") {
      final value = "text/plain: " + artifact.stringValue;
      return Linkify(
        onOpen: (link) async {
          if (await canLaunch(link.url)) {
            await launch(link.url);
          } else {
            throw 'Could not launch $link';
          }
        },
        text: value,
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.bodyText2,
        linkStyle: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(color: Theme.of(context).accentColor),
      );
    }
    return Text(
      artifact.mimeType,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodyText2,
    );
  }

  Widget _itemBuilder(context, Artifact artifact, index) {
    String artifactInfoLink;
    switch (artifact.mimeType) {
      case "application/octet-stream;type=gnostic.metrics.Vocabulary":
        artifactInfoLink =
            "https://github.com/google/gnostic/blob/master/metrics/vocabulary.proto#L27";
        break;
      case "application/octet-stream;type=gnostic.metrics.Complexity":
        artifactInfoLink =
            "https://github.com/google/gnostic/blob/master/metrics/complexity.proto#L23";
        break;
      case "application/octet-stream;type=google.cloud.apigee.registry.applications.v1alpha1.Lint":
        artifactInfoLink =
            "https://github.com/apigee/registry/blob/main/google/cloud/apigee/registry/v1/registry_lint.proto#L38";
        break;
      case "application/octet-stream;type=google.cloud.apigee.registry.applications.v1alpha1.LintStats":
        artifactInfoLink =
            "https://github.com/apigee/registry/blob/main/google/cloud/apigee/registry/v1/registry_lint.proto#L91";
        break;
    }
    bool canDelete = artifact.mimeType == "text/plain";
    return ListTile(
      title: Text(artifact.nameForDisplay()),
      subtitle: widgetForArtifactValue(artifact),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection selection = SelectionProvider.of(context);
        selection?.updateArtifactName(artifact.name);
        widget.selectionHandler?.call(context, artifact);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (artifactInfoLink != null)
            IconButton(
                color: Colors.black,
                icon: Icon(Icons.info),
                tooltip: "info",
                onPressed: () async {
                  if (await canLaunch(artifactInfoLink)) {
                    await launch(artifactInfoLink);
                  } else {
                    throw 'Could not launch $artifactInfoLink';
                  }
                }),
          if (canDelete)
            IconButton(
              color: Colors.black,
              icon: Icon(Icons.delete),
              tooltip: "delete",
              onPressed: () {
                final selection = SelectionProvider.of(context);
                selection.updateArtifactName(artifact.name);
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SelectionProvider(
                        selection: selection,
                        child: AlertDialog(
                          content: DeleteArtifactForm(),
                        ),
                      );
                    });
              },
            ),
        ],
      ),
    );
  }
}

// ArtifactSearchBox provides a search box for artifacts.
class ArtifactSearchBox extends CustomSearchBox {
  ArtifactSearchBox()
      : super(
          "Filter Artifacts",
          "artifact_id.contains('TEXT')",
        );
}
