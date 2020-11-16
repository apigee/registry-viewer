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
import '../helpers/title.dart';
import '../components/logout.dart';
import 'home.dart';

const int pageSize = 50;

// convert /projects/{project}/apis/{api}/versions/{version}/specs
// to projects/{project}/apis/{api}/versions/{version}
String parent(String name) {
  var parts = name.split('/');
  return parts.sublist(1, 7).join('/');
}

// SpecListPage is a full-page display of a list of specs.
class SpecListPage extends StatelessWidget {
  final String name;
  final String versionName;
  SpecListPage(String name, {Key key})
      : name = name,
        versionName = parent(name),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var specList = SpecList(SpecService(versionName));
    return Scaffold(
      appBar: AppBar(
        title: Text(title(name)),
        actions: <Widget>[
          SpecSearchBox(specList),
          logoutButton(context),
        ],
      ),
      body: Center(child: specList),
    );
  }
}

// SpecListCard is a card that displays a list of specs.
class SpecListCard extends StatefulWidget {
  @override
  _SpecListCardState createState() => _SpecListCardState();
}

class _SpecListCardState extends State<SpecListCard> {
  String versionName;

  @override
  void didChangeDependencies() {
    ModelProvider.of(context).addListener(() => setState(() {}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    versionName = ModelProvider.of(context).version;
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
            leading: GestureDetector(
                child: Icon(
                  Icons.bookmark_border,
                  color: Colors.black,
                ),
                onTap: () async {
                  print("save this API");
                }),
            title: Text(
              spec.nameForDisplay(),
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("$spec"),
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
            hintText: 'Search API specs'),
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
