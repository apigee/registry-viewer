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
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_models.pb.dart';
import '../helpers/title.dart';
import '../components/home_button.dart';
import '../components/spec_list.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../models/spec.dart';
import '../service/service.dart';

// SpecListPage is a full-page display of a list of specs.
class SpecListPage extends StatefulWidget {
  final String name;

  SpecListPage(String name, {Key key})
      : name = name,
        super(key: key);
  @override
  _SpecListPageState createState() => _SpecListPageState();
}

class _SpecListPageState extends State<SpecListPage> {
  SpecService specService;
  PagewiseLoadController<ApiSpec> pageLoadController;

  _SpecListPageState() {
    specService = SpecService();
    pageLoadController = PagewiseLoadController<ApiSpec>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => this.specService.getSpecsPage(pageIndex));
  }

  // convert /projects/{project}/apis/{api}/versions/{version}/specs
  // to projects/{project}/apis/{api}/versions/{version}
  String parentName() {
    return widget.name.split('/').sublist(1, 7).join('/');
  }

  @override
  Widget build(BuildContext context) {
    final selectionModel = Selection();
    selectionModel.versionName.update(parentName());
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title(widget.name)),
            actions: <Widget>[
              Container(width: 400, child: SpecSearchBox()),
              homeButton(context),
            ],
          ),
          body: Center(
            child: SpecListView(
              (context, spec) {
                Navigator.pushNamed(
                  context,
                  spec.routeNameForDetail(),
                  arguments: spec,
                );
              },
              specService,
              pageLoadController,
            ),
          ),
        ),
      ),
    );
  }
}
