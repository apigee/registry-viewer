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
import '../models/spec.dart';
import '../models/selection.dart';

const int pageSize = 50;

typedef SpecSelectionHandler = Function(BuildContext context, Spec spec);

// SpecListCard is a card that displays a list of specs.
class SpecListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            SpecSearchBox(),
            Expanded(child: SpecList(null)),
          ],
        ),
      ),
    );
  }
}

// SpecList contains a ListView of specs.
class SpecList extends StatefulWidget {
  final SpecSelectionHandler selectionHandler;
  SpecList(this.selectionHandler);
  @override
  _SpecListState createState() => _SpecListState();
}

class _SpecListState extends State<SpecList> {
  String versionName;
  PagewiseLoadController<Spec> pageLoadController;
  SpecService specService;
  int selectedIndex = -1;

  _SpecListState() {
    specService = SpecService();
    pageLoadController = PagewiseLoadController<Spec>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => specService.getSpecsPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).version.addListener(() => setState(() {}));
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
    if (specService.versionName !=
        SelectionProvider.of(context).version.value) {
      specService.versionName = SelectionProvider.of(context).version.value;
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
    return ListTile(
      title: Text(spec.nameForDisplay()),
      subtitle: Text(spec.style),
      selected: index == selectedIndex,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        if (widget.selectionHandler != null) {
          widget.selectionHandler(context, spec);
        }
      },
    );
  }
}

// SpecSearchBox provides a search box for specs.
class SpecSearchBox extends StatelessWidget {
  SpecSearchBox();
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
            hintText: 'Filter API specs'),
        onSubmitted: (s) {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            if (s == "") {
              filter.update("");
            } else {
              filter.update("spec_id.contains('$s')");
            }
          }
        },
      ),
    );
  }
}
