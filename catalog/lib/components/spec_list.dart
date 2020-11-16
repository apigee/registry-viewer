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

// SpecListCard is a card that displays a list of specs.
class SpecListCard extends StatefulWidget {
  @override
  _SpecListCardState createState() => _SpecListCardState();
}

class _SpecListCardState extends State<SpecListCard> {
  String versionName;

  @override
  void didChangeDependencies() {
    ModelProvider.of(context).version.addListener(() => setState(() {}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    versionName = ModelProvider.of(context).version.value;
    var specList = SpecList(SpecService(versionName));
    return Card(
      child: Column(
        children: [
          SpecSearchBox(specList),
          Expanded(child: specList),
        ],
      ),
    );
  }
}

// SpecList contains a ListView of specs.
class SpecList extends StatelessWidget {
  final PagewiseLoadController<Spec> pageLoadController;
  final SpecService specService;

  SpecList(SpecService specService)
      : specService = specService,
        pageLoadController = PagewiseLoadController<Spec>(
            pageSize: pageSize,
            pageFuture: (pageIndex) => specService.getSpecsPage(pageIndex));

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: PagewiseListView<Spec>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Spec spec, _) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            Navigator.pushNamed(
              context,
              spec.routeNameForDetail(),
              arguments: spec,
            );
          },
          child: ListTile(
            title: Text(spec.nameForDisplay()),
            subtitle: Text(spec.style),
          ),
        ),
        Divider(thickness: 2)
      ],
    );
  }
}

// SpecSearchBox provides a search box for specs.
class SpecSearchBox extends StatelessWidget {
  final SpecList specList;
  SpecSearchBox(this.specList);
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
          if (s == "") {
            specList.specService.filter = "";
          } else {
            specList.specService.filter = "spec_id.contains('$s')";
          }
          specList.pageLoadController.reset();
        },
      ),
    );
  }
}