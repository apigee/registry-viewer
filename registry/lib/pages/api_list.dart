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
import '../helpers/title.dart';
import '../components/api_list.dart';
import '../components/home_button.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../models/api.dart';
import '../service/service.dart';

// ApiListPage is a full-page display of a list of apis.
class ApiListPage extends StatefulWidget {
  final String name;

  ApiListPage(String name, {Key key})
      : name = name,
        super(key: key);
  @override
  _ApiListPageState createState() => _ApiListPageState();
}

class _ApiListPageState extends State<ApiListPage> {
  ApiService apiService;
  PagewiseLoadController<Api> pageLoadController;

  _ApiListPageState() {
    apiService = ApiService();
    pageLoadController = PagewiseLoadController<Api>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => apiService.getApisPage(pageIndex));
  }

  // convert /projects/{project}/apis to projects/{project}
  String parentName() {
    return widget.name.split('/').sublist(1, 3).join('/');
  }

  @override
  Widget build(BuildContext context) {
    final selectionModel = Selection();
    selectionModel.projectName.update(parentName());
    return SelectionProvider(
      selection: selectionModel,
      child: ObservableStringProvider(
        observable: ObservableString(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title(widget.name)),
            actions: <Widget>[
              Container(width: 400, child: ApiSearchBox()),
              homeButton(context),
            ],
          ),
          body: Center(
            child: ApiListView(
              (context, api) {
                Navigator.pushNamed(
                  context,
                  api.routeNameForDetail(),
                  arguments: api,
                );
              },
              apiService,
              pageLoadController,
            ),
          ),
        ),
      ),
    );
  }
}
