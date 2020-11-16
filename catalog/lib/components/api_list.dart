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
import '../models/api.dart';
import '../models/selection.dart';

const int pageSize = 50;

// ApiListCard is a card that displays a list of projects.
class ApiListCard extends StatefulWidget {
  @override
  _ApiListCardState createState() => _ApiListCardState();
}

class _ApiListCardState extends State<ApiListCard> {
  String projectName;

  @override
  void didChangeDependencies() {
    ModelProvider.of(context).project.addListener(() => setState(() {}));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    projectName = ModelProvider.of(context).project.value;
    var apiList = ApiList(ApiService(projectName));
    return Card(
      child: Column(
        children: [
          ApiSearchBox(apiList),
          Expanded(child: apiList),
        ],
      ),
    );
  }
}

// ApiList contains a ListView of apis.
class ApiList extends StatelessWidget {
  final PagewiseLoadController<Api> pageLoadController;
  final ApiService apiService;

  ApiList(ApiService apiService)
      : apiService = apiService,
        pageLoadController = PagewiseLoadController<Api>(
            pageSize: pageSize,
            pageFuture: (pageIndex) => apiService.getApisPage(pageIndex));

  @override
  Widget build(BuildContext context) {
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
            SelectionModel model = ModelProvider.of(context);
            if (model != null) {
              print("tapped for api ${api.name}");
              model.updateApi(api.name);
            } else {
              Navigator.pushNamed(
                context,
                api.routeNameForDetail(),
                arguments: api,
              );
            }
          },
          child: ListTile(
            title: Text(api.nameForDisplay()),
            subtitle: Text(api.owner),
          ),
        ),
        Divider(thickness: 2)
      ],
    );
  }
}

// ApiSearchBox provides a search box for apis.
class ApiSearchBox extends StatelessWidget {
  final ApiList apiList;
  ApiSearchBox(this.apiList);
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
            hintText: 'Filter APIs'),
        onSubmitted: (s) {
          if (s == "") {
            apiList.apiService.filter = "";
          } else {
            apiList.apiService.filter = "api_id.contains('$s')";
          }
          apiList.pageLoadController.reset();
        },
      ),
    );
  }
}