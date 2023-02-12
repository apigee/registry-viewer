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
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final bool singleColumn;
  const ArtifactListCard(this.getObservableResourceName,
      {required this.singleColumn});

  @override
  ArtifactListCardState createState() => ArtifactListCardState();
}

class ArtifactListCardState extends State<ArtifactListCard>
    with AutomaticKeepAliveClientMixin {
  late ObservableString observableSubjectName;
  String? subjectName;
  ArtifactService? artifactService;
  PagewiseLoadController<Artifact>? pageLoadController;
  @override
  bool get wantKeepAlive => true;

  ArtifactListCardState() {
    artifactService = ArtifactService();
    pageLoadController = PagewiseLoadController<Artifact>(
        pageSize: pageSize,
        pageFuture: ((pageIndex) => artifactService!
            .getArtifactsPage(pageIndex!)
            .then((value) => value!)));
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
    super.build(context);
    Function add = () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: AlertDialog(
                content: AddArtifactForm(subjectName!),
              ),
            );
          });
    };
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, const ArtifactSearchBox(),
                type: "artifacts",
                add: add,
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: ArtifactListView(
                widget.getObservableResourceName,
                null,
                artifactService,
                pageLoadController,
                widget.singleColumn,
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
  final ObservableStringFn? getObservableResourceName;
  final ArtifactSelectionHandler? selectionHandler;
  final ArtifactService? artifactService;
  final PagewiseLoadController<Artifact>? pageLoadController;
  final bool singleColumn;

  const ArtifactListView(
    this.getObservableResourceName,
    this.selectionHandler,
    this.artifactService,
    this.pageLoadController,
    this.singleColumn,
  );
  @override
  ArtifactListViewState createState() => ArtifactListViewState();
}

class ArtifactListViewState extends State<ArtifactListView> {
  String? parentName;
  int selectedIndex = -1;
  ObservableString? filter;
  final ScrollController scrollController = ScrollController();

  void filterListener() {
    setState(() {
      ObservableString? filter = ObservableStringProvider.of(context);
      if (filter != null) {
        widget.artifactService!.filter = filter.value;
        widget.pageLoadController!.reset();
        selectedIndex = -1;
      }
      SelectionProvider.of(context)?.updateArtifactName("");
    });
  }

  @override
  void didChangeDependencies() {
    filter = ObservableStringProvider.of(context);
    filter!.addListener(filterListener);
    super.didChangeDependencies();
    filterListener();
  }

  @override
  void dispose() {
    filter!.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.artifactService!.context = context;
    String subjectName = widget.getObservableResourceName!(context).value;
    if (widget.artifactService!.parentName != subjectName) {
      widget.artifactService!.parentName = subjectName;
      widget.pageLoadController!.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<Artifact>(
        itemBuilder: _itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget widgetForArtifactValue(Artifact artifact) {
    final style = GoogleFonts.inconsolata();
    return Text(
      artifact.mimeType,
      textAlign: TextAlign.left,
      style: style,
    );
  }

  Widget _itemBuilder(context, Artifact artifact, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.artifactName.value == "")) {
          selection.updateArtifactName(artifact.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(artifact.nameForDisplay()),
      subtitle: widgetForArtifactValue(artifact),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          if (widget.singleColumn) {
            Navigator.pushNamed(
              context,
              artifact.routeNameForDetail(),
            );
          } else {
            selectedIndex = index;
          }
        });
        Selection? selection = SelectionProvider.of(context);
        selection?.updateArtifactName(artifact.name);
        widget.selectionHandler?.call(context, artifact);
      },
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        tooltip: "open",
        onPressed: () {
          Navigator.pushNamed(
            context,
            artifact.routeNameForDetail(),
          );
        },
      ),
    );
  }
}

// ArtifactSearchBox provides a search box for artifacts.
class ArtifactSearchBox extends CustomSearchBox {
  const ArtifactSearchBox()
      : super(
          "Filter Artifacts",
          "artifact_id.contains('TEXT')",
        );
}
