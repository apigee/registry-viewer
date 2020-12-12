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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/spec.dart';
import '../models/string.dart';
import '../models/selection.dart';
import 'custom_search_box.dart';
import 'filter.dart';

const int pageSize = 50;

typedef SpecSelectionHandler = Function(BuildContext context, Spec spec);

PagewiseLoadController<Spec> pageLoadController;

// SpecListCard is a card that displays a list of specs.
class SpecListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, SpecSearchBox(),
                refresh: () => pageLoadController.reset()),
            Expanded(child: SpecListView(null)),
          ],
        ),
      ),
    );
  }
}

// SpecListView is a scrollable ListView of specs.
class SpecListView extends StatefulWidget {
  final SpecSelectionHandler selectionHandler;
  SpecListView(this.selectionHandler);
  @override
  _SpecListViewState createState() => _SpecListViewState();
}

class _SpecListViewState extends State<SpecListView> {
  String versionName;
  // PagewiseLoadController<Spec> pageLoadController;
  SpecService specService;
  int selectedIndex = -1;

  _SpecListViewState() {
    specService = SpecService();
    pageLoadController = PagewiseLoadController<Spec>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => specService.getSpecsPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context)
        .versionName
        .addListener(() => setState(() {}));
    ObservableStringProvider.of(context).addListener(() => setState(() {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            specService.filter = filter.value;
            pageLoadController.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    specService.context = context;
    if (specService.versionName !=
        SelectionProvider.of(context).versionName.value) {
      specService.versionName = SelectionProvider.of(context).versionName.value;
      pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Spec>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Spec spec, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection selection = SelectionProvider.of(context);
        if ((selection != null) &&
            ((selection.specName.value == null) ||
                (selection.specName.value == ""))) {
          selection.updateSpecName(spec.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(spec.nameForDisplay()),
      subtitle: Text(spec.style),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection selection = SelectionProvider.of(context);
        selection?.updateSpecName(spec.name);
        widget.selectionHandler?.call(context, spec);
      },
      trailing: IconButton(
        color: Colors.black,
        icon: Icon(Icons.open_in_new),
        tooltip: "open",
        onPressed: () {
          Navigator.pushNamed(
            context,
            spec.routeNameForDetail(),
          );
        },
      ),
    );
  }
}

// SpecSearchBox provides a search box for specs.
class SpecSearchBox extends CustomSearchBox {
  SpecSearchBox() : super("Filter Specs", "spec_id.contains('TEXT')");
}
