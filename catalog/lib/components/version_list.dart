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
import '../models/version.dart';
import '../models/selection.dart';

const int pageSize = 50;

typedef VersionSelectionHandler = Function(
    BuildContext context, Version version);

// VersionListCard is a card that displays a list of versions.
class VersionListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            VersionSearchBox(),
            Expanded(child: VersionList(null)),
          ],
        ),
      ),
    );
  }
}

// VersionList contains a ListView of versions.
class VersionList extends StatefulWidget {
  final VersionSelectionHandler selectionHandler;
  VersionList(this.selectionHandler);
  @override
  _VersionListState createState() => _VersionListState();
}

class _VersionListState extends State<VersionList> {
  String apiName;
  PagewiseLoadController<Version> pageLoadController;
  VersionService versionService;
  int selectedIndex = -1;

  _VersionListState() {
    versionService = VersionService();
    pageLoadController = PagewiseLoadController<Version>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => versionService.getVersionsPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).api.addListener(() => setState(() {}));
    ObservableStringProvider.of(context).addListener(() => setState(() {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            versionService.filter = filter.value;
            pageLoadController.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (versionService.apiName != SelectionProvider.of(context).api.value) {
      versionService.apiName = SelectionProvider.of(context).api.value;
      pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Version>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Version version, index) {
    return ListTile(
      title: Text(version.nameForDisplay()),
      subtitle: Text(version.description),
      selected: index == selectedIndex,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        SelectionModel model = SelectionProvider.of(context);
        if (model != null) {
          model.updateVersion(version.name);
        }
        if (widget.selectionHandler != null) {
          widget.selectionHandler(context, version);
        }
      },
    );
  }
}

// VersionSearchBox provides a search box for versions.
class VersionSearchBox extends StatelessWidget {
  VersionSearchBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        8,
      ),
      alignment: Alignment.centerLeft,
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: Colors.black),
            border: InputBorder.none,
            hintText: 'Filter API versions'),
        onSubmitted: (s) {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            if (s == "") {
              filter.update("");
            } else {
              filter.update("version_id.contains('$s')");
            }
          }
        },
      ),
    );
  }
}
