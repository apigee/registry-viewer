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
import '../components/help.dart';
import '../application.dart';
import '../models/spec.dart';

class SpecListPage extends StatelessWidget {
  final String title;
  final String versionID;
  SpecListPage({Key key, this.title, this.versionID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SpecService.versionID = versionID; // HACK
    return Scaffold(
      appBar: AppBar(
        title: Text("Specs"),
        actions: <Widget>[
          SpecSearchBox(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            tooltip: 'Log out',
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
          ),
        ],
      ),
      body: Center(
        child: SpecList(),
      ),
    );
  }
}

const int pageSize = 50;
PagewiseLoadController<Spec> pageLoadController;

class SpecList extends StatelessWidget {
  SpecList();

  @override
  Widget build(BuildContext context) {
    pageLoadController = PagewiseLoadController<Spec>(
        pageSize: pageSize,
        pageFuture: (pageIndex) =>
            SpecService.getSpecsPage(context, pageIndex));
    return Scrollbar(
      child: PagewiseListView<Spec>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Spec entry, _) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            Navigator.pushNamed(
              context,
              entry.routeNameForSpecDetail(),
              arguments: entry,
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
              entry.nameForDisplay(),
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("$entry"),
          ),
        ),
        Divider(thickness: 2)
      ],
    );
  }
}

class SpecSearchBox extends StatelessWidget {
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
            SpecService.filter = "";
          } else {
            SpecService.filter = "spec_id.contains('$s')";
          }
          pageLoadController.reset();
        },
      ),
    );
  }
}
