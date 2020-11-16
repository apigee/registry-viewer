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

// VersionListCard is a card that displays a list of versions.
class VersionListCard extends StatefulWidget {
  @override
  _VersionListCardState createState() => _VersionListCardState();
}

class _VersionListCardState extends State<VersionListCard> {
  String apiName;

  @override
  void didChangeDependencies() {
    ModelProvider.of(context).api.addListener(() => setState(() {}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    apiName = ModelProvider.of(context).api.value;
    var versionList = VersionList(VersionService(apiName));
    return Card(
      child: Column(
        children: [
          VersionSearchBox(versionList),
          Expanded(child: versionList),
        ],
      ),
    );
  }
}

// VersionList contains a ListView of versions.
class VersionList extends StatelessWidget {
  final PagewiseLoadController<Version> pageLoadController;
  final VersionService versionService;

  VersionList(VersionService versionService)
      : versionService = versionService,
        pageLoadController = PagewiseLoadController<Version>(
            pageSize: pageSize,
            pageFuture: (pageIndex) =>
                versionService.getVersionsPage(pageIndex));

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: PagewiseListView<Version>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Version version, _) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () async {
            SelectionModel model = ModelProvider.of(context);
            if (model != null) {
              print("tapped for version ${version.name}");
              model.updateVersion(version.name);
            } else {
              Navigator.pushNamed(
                context,
                version.routeNameForDetail(),
                arguments: version,
              );
            }
          },
          child: ListTile(
            title: Text(version.nameForDisplay()),
            subtitle: Text(version.description),
          ),
        ),
        Divider(thickness: 2)
      ],
    );
  }
}

// VersionSearchBox provides a search box for versions.
class VersionSearchBox extends StatelessWidget {
  final VersionList versionList;
  VersionSearchBox(this.versionList);
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
          if (s == "") {
            versionList.versionService.filter = "";
          } else {
            versionList.versionService.filter = "version_id.contains('$s')";
          }
          versionList.pageLoadController.reset();
        },
      ),
    );
  }
}
