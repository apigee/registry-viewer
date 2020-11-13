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
import '../components/drawer.dart';
import '../helpers/adaptive.dart';
import '../components/help.dart';
import '../models/api.dart';
import '../helpers/title.dart';

class ApiListPage extends StatelessWidget {
  final String name;
  final Project project;
  ApiListPage({Key key, this.name, this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ApiService.projectName = project.name; // HACK

    final isDesktop = isDisplayDesktop(context);

    if (isDesktop) {
      return Center(
        child: Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: buildAppBar(context, isDesktop),
                body: ApiList(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: buildAppBar(context, isDesktop),
        body: ApiList(),
      );
    }
  }

  AppBar buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      title: Text(title(name)),
      actions: <Widget>[
        ApiSearchBox(),
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
    );
  }
}

const int pageSize = 50;
PagewiseLoadController<Api> pageLoadController;

class ApiList extends StatelessWidget {
  ApiList();

  @override
  Widget build(BuildContext context) {
    pageLoadController = PagewiseLoadController<Api>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => ApiService.getApisPage(context, pageIndex));
    return Scrollbar(
      child: PagewiseListView<Api>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Api api, _) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            Navigator.pushNamed(
              context,
              api.routeNameForDetail(),
              arguments: api,
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
              api.displayName,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(api.owner),
          ),
        ),
        Divider(thickness: 2)
      ],
    );
  }
}

class ApiSearchBox extends StatelessWidget {
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
            hintText: 'Search APIs'),
        onSubmitted: (s) {
          if (s == "") {
            ApiService.filter = "";
          } else {
            ApiService.filter = "api_id.contains('$s')";
          }
          pageLoadController.reset();
        },
      ),
    );
  }
}
