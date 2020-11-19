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
import 'custom_search_box.dart';

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
    versionService.context = context;
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
    if (index == 0) {
      Future.delayed(const Duration(milliseconds: 0), () {
        SelectionModel model = SelectionProvider.of(context);
        if ((model != null) &&
            ((model.version.value == null) || (model.version.value == ""))) {
          model.updateVersion(version.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(version.nameForDisplay()),
      subtitle: Text(version.state),
      selected: index == selectedIndex,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        SelectionModel model = SelectionProvider.of(context);
        model?.updateVersion(version.name);
        widget.selectionHandler?.call(context, version);
      },
    );
  }
}

// VersionSearchBox provides a search box for versions.
class VersionSearchBox extends CustomSearchBox {
  VersionSearchBox()
      : super("Filter API versions", "version_id.contains('TEXT')");
}
