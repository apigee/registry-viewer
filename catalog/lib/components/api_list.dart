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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/api.dart';
import '../models/selection.dart';
import 'custom_search_box.dart';

const int pageSize = 50;

typedef ApiSelectionHandler = Function(BuildContext context, Api api);

// ApiListCard is a card that displays a list of projects.
class ApiListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            ApiSearchBox(),
            Expanded(child: ApiListView(null)),
          ],
        ),
      ),
    );
  }
}

// ApiListView is a scrollable ListView of apis.
class ApiListView extends StatefulWidget {
  final ApiSelectionHandler selectionHandler;
  ApiListView(this.selectionHandler);

  @override
  _ApiListViewState createState() => _ApiListViewState();
}

class _ApiListViewState extends State<ApiListView> {
  String projectName;
  PagewiseLoadController<Api> pageLoadController;
  ApiService apiService;
  int selectedIndex = -1;

  _ApiListViewState() {
    apiService = ApiService();
    pageLoadController = PagewiseLoadController<Api>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => apiService.getApisPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).project.addListener(() => setState(() {}));
    ObservableStringProvider.of(context).addListener(() => setState(() {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            apiService.filter = filter.value;
            pageLoadController.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    apiService.context = context;
    if (apiService.projectName != SelectionProvider.of(context).project.value) {
      apiService.projectName = SelectionProvider.of(context).project.value;
      pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Api>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Api api, index) {
    if (index == 0) {
      Future.delayed(const Duration(milliseconds: 0), () {
        Selection selection = SelectionProvider.of(context);
        if ((selection != null) &&
            ((selection.api.value == null) || (selection.api.value == ""))) {
          selection.updateApi(api.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(api.nameForDisplay()),
      subtitle: Text(api.owner),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection selection = SelectionProvider.of(context);
        selection?.updateApi(api.name);
        widget.selectionHandler?.call(context, api);
      },
    );
  }
}

// ApiSearchBox provides a search box for apis.
class ApiSearchBox extends CustomSearchBox {
  ApiSearchBox() : super("Filter APIs", "api_id.contains('TEXT')");
}
