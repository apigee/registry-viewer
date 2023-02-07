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
import '../models/selection.dart';
import '../models/string.dart';
import '../models/version.dart';
import '../service/service.dart';

typedef VersionSelectionHandler = Function(
    BuildContext context, ApiVersion version);

// VersionListCard is a card that displays a list of versions.
class VersionListCard extends StatefulWidget {
  final bool singleColumn;
  VersionListCard({required this.singleColumn});

  @override
  _VersionListCardState createState() => _VersionListCardState();
}

class _VersionListCardState extends State<VersionListCard>
    with AutomaticKeepAliveClientMixin {
  VersionService? versionService;
  PagewiseLoadController<ApiVersion>? pageLoadController;
  @override
  bool get wantKeepAlive => true;

  _VersionListCardState() {
    versionService = VersionService();
    pageLoadController = PagewiseLoadController<ApiVersion>(
        pageSize: pageSize,
        pageFuture: ((pageIndex) => versionService!
            .getVersionsPage(pageIndex!)
            .then((value) => value!)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, VersionSearchBox(),
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: VersionListView(
                null,
                versionService,
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

// VersionListView is a scrollable ListView of versions.
class VersionListView extends StatefulWidget {
  final VersionSelectionHandler? selectionHandler;
  final VersionService? versionService;
  final PagewiseLoadController<ApiVersion>? pageLoadController;
  final bool singleColumn;

  VersionListView(
    this.selectionHandler,
    this.versionService,
    this.pageLoadController,
    this.singleColumn,
  );

  @override
  _VersionListViewState createState() => _VersionListViewState();
}

class _VersionListViewState extends State<VersionListView> {
  String? apiName;
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
        widget.versionService!.filter = filter.value;
        widget.pageLoadController!.reset();
        selectedIndex = -1;
      }
      SelectionProvider.of(context)?.updateVersionName("");
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.apiName.addListener(selectionListener);
    filter = ObservableStringProvider.of(context);
    filter!.addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    selection!.apiName.removeListener(selectionListener);
    filter!.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.versionService!.context = context;
    if (widget.versionService!.apiName !=
        SelectionProvider.of(context)!.apiName.value) {
      widget.versionService!.apiName =
          SelectionProvider.of(context)!.apiName.value;
      widget.pageLoadController!.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<ApiVersion>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget _itemBuilder(context, ApiVersion version, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.versionName.value == "")) {
          selection.updateVersionName(version.name);
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
          version.routeNameForDetail(),
        );
      },
      child: ListTile(
        title: Text(version.nameForDisplay()),
        selected: index == selectedIndex,
        dense: false,
        onTap: () async {
          setState(() {
            if (widget.singleColumn) {
              Navigator.pushNamed(
                context,
                version.routeNameForDetail(),
              );
            } else {
              selectedIndex = index;
            }
          });
          Selection? selection = SelectionProvider.of(context);
          selection?.updateVersionName(version.name);
          widget.selectionHandler?.call(context, version);
        },
        trailing: IconButton(
          //color: Colors.black,
          icon: Icon(Icons.open_in_new),
          tooltip: "open",
          onPressed: () {
            Navigator.pushNamed(
              context,
              version.routeNameForDetail(),
            );
          },
        ),
      ),
    );
  }
}

// VersionSearchBox provides a search box for versions.
class VersionSearchBox extends CustomSearchBox {
  VersionSearchBox() : super("Filter Versions", "version_id.contains('TEXT')");
}
