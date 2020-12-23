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
import '../components/property_list.dart';
import '../components/home_button.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../models/property.dart';
import '../service/service.dart';

// PropertyListPage is a full-page display of a list of properties.
class PropertyListPage extends StatefulWidget {
  final String name;

  PropertyListPage(String name, {Key key})
      : name = name,
        super(key: key);
  @override
  _PropertyListPageState createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  PropertyService propertyService;
  PagewiseLoadController<Property> pageLoadController;

  _PropertyListPageState() {
    propertyService = PropertyService();
    pageLoadController = PagewiseLoadController<Property>(
        pageSize: pageSize,
        pageFuture: (pageIndex) =>
            propertyService.getPropertiesPage(pageIndex));
  }

  // convert /projects/{project}/properties to projects/{project}
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
              Container(width: 400, child: PropertySearchBox()),
              homeButton(context),
            ],
          ),
          body: Center(
            child: PropertyListView(
              null,
              (context, property) {
                Navigator.pushNamed(
                  context,
                  property.routeNameForDetail(),
                  arguments: property,
                );
              },
              propertyService,
              pageLoadController,
            ),
          ),
        ),
      ),
    );
  }
}
