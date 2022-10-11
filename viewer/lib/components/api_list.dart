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
import '../models/api.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../service/service.dart';

typedef ApiSelectionHandler = Function(BuildContext context, Api api);

// ApiListCard is a card that displays a list of apis.
class ApiListCard extends StatefulWidget {
  @override
  _ApiListCardState createState() => _ApiListCardState();
}

class _ApiListCardState extends State<ApiListCard> {
  ApiService? apiService;
  PagewiseLoadController<Api>? pageLoadController;

  _ApiListCardState() {
    apiService = ApiService();
    pageLoadController = PagewiseLoadController<Api>(
        pageSize: pageSize,
        pageFuture: ((pageIndex) =>
            apiService!.getApisPage(pageIndex!).then((value) => value!)));
  }

  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, ApiSearchBox(),
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: ApiListView(
                null,
                apiService,
                pageLoadController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ApiListView is a scrollable ListView of apis.
class ApiListView extends StatefulWidget {
  final ApiSelectionHandler? selectionHandler;
  final ApiService? apiService;
  final PagewiseLoadController<Api>? pageLoadController;

  ApiListView(
    this.selectionHandler,
    this.apiService,
    this.pageLoadController,
  );

  @override
  _ApiListViewState createState() => _ApiListViewState();
}

class _ApiListViewState extends State<ApiListView> {
  String? projectName;
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
        widget.apiService!.filter = filter.value;
        widget.pageLoadController!.reset();
        selectedIndex = -1;
      }
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.projectName.addListener(selectionListener);
    filter = ObservableStringProvider.of(context);
    filter!.addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    selection!.projectName.removeListener(selectionListener);
    filter!.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.apiService!.context = context;
    if (widget.apiService!.projectName !=
        SelectionProvider.of(context)!.projectName.value) {
      widget.apiService!.projectName =
          SelectionProvider.of(context)!.projectName.value;
      widget.pageLoadController!.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<Api>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget _itemBuilder(context, Api api, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.apiName.value == "")) {
          selection.updateApiName(api.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(api.nameForDisplay()),
      subtitle: Text(api.description),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection? selection = SelectionProvider.of(context);
        selection?.updateApiName(api.name);
        widget.selectionHandler?.call(context, api);
      },
      trailing: IconButton(
        color: Colors.black,
        icon: Icon(Icons.open_in_new),
        tooltip: "open",
        onPressed: () {
          Navigator.pushNamed(
            context,
            api.routeNameForDetail(),
          );
        },
      ),
    );
  }
}

// ApiSearchBox provides a search box for apis.
class ApiSearchBox extends CustomSearchBox {
  ApiSearchBox()
      : super(
          "Filter APIs",
          "api_id.contains('TEXT')",
        );
}
