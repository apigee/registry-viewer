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
import '../components/custom_search_box.dart';
import '../components/filter.dart';
import '../models/spec.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../service/service.dart';

typedef SpecSelectionHandler = Function(BuildContext context, ApiSpec spec);

// SpecListCard is a card that displays a list of specs.
class SpecListCard extends StatefulWidget {
  final bool singleColumn;
  const SpecListCard({required this.singleColumn});

  @override
  _SpecListCardState createState() => _SpecListCardState();
}

class _SpecListCardState extends State<SpecListCard>
    with AutomaticKeepAliveClientMixin {
  SpecService? specService;
  PagewiseLoadController<ApiSpec>? pageLoadController;
  @override
  bool get wantKeepAlive => true;

  _SpecListCardState() {
    specService = SpecService();
    pageLoadController = PagewiseLoadController<ApiSpec>(
        pageSize: pageSize,
        pageFuture: ((pageIndex) =>
            specService!.getSpecsPage(pageIndex!).then((value) => value!)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, SpecSearchBox(),
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: SpecListView(
                null,
                specService,
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

// SpecListView is a scrollable ListView of specs.
class SpecListView extends StatefulWidget {
  final SpecSelectionHandler? selectionHandler;
  final SpecService? specService;
  final PagewiseLoadController<ApiSpec>? pageLoadController;
  final bool singleColumn;

  const SpecListView(
    this.selectionHandler,
    this.specService,
    this.pageLoadController,
    this.singleColumn,
  );

  @override
  _SpecListViewState createState() => _SpecListViewState();
}

class _SpecListViewState extends State<SpecListView> {
  String? versionName;
  int selectedIndex = -1;
  Selection? selection;
  ObservableString? filter;
  final ScrollController scrollController = ScrollController();

  void selectionListener() {
    setState(() {});
  }

  void filterListener() {
    setState(() {
      ObservableString? filter = ObservableStringProvider.of(context);
      if (filter != null) {
        widget.specService!.filter = filter.value;
        widget.pageLoadController!.reset();
        selectedIndex = -1;
      }
      SelectionProvider.of(context)?.updateSpecName("");
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.versionName.addListener(selectionListener);
    filter = ObservableStringProvider.of(context);
    filter!.addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    selection!.versionName.removeListener(selectionListener);
    filter!.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.specService!.context = context;
    if (widget.specService!.versionName !=
        SelectionProvider.of(context)!.versionName.value) {
      widget.specService!.versionName =
          SelectionProvider.of(context)!.versionName.value;
      widget.pageLoadController!.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<ApiSpec>(
        itemBuilder: _itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget _itemBuilder(context, ApiSpec spec, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.specName.value == "")) {
          selection.updateSpecName(spec.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return GestureDetector(
      onDoubleTap: () async {
        Navigator.pushNamed(
          context,
          spec.routeNameForDetail(),
        );
      },
      child: ListTile(
        title: Text(spec.nameForDisplay()),
        subtitle: Text(spec.mimeType),
        selected: index == selectedIndex,
        dense: false,
        onTap: () async {
          setState(() {
            if (widget.singleColumn) {
              Navigator.pushNamed(
                context,
                spec.routeNameForDetail(),
              );
            } else {
              selectedIndex = index;
            }
          });
          Selection? selection = SelectionProvider.of(context);
          selection?.updateSpecName(spec.name);
          widget.selectionHandler?.call(context, spec);
        },
        trailing: IconButton(
          //color: Colors.black,
          icon: Icon(Icons.open_in_new),
          tooltip: "open",
          onPressed: () {
            Navigator.pushNamed(
              context,
              spec.routeNameForDetail(),
            );
          },
        ),
      ),
    );
  }
}

// SpecSearchBox provides a search box for specs.
class SpecSearchBox extends CustomSearchBox {
  const SpecSearchBox()
      : super(
          "Filter Specs",
          "spec_id.contains('TEXT')",
        );
}
