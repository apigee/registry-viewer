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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:catalog/generated/metrics/complexity.pb.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// SpecComplexityCard

class SpecComplexityCard extends StatefulWidget {
  @override
  _SpecComplexityCardState createState() => _SpecComplexityCardState();
}

class _SpecComplexityCardState extends State<SpecComplexityCard> {
  PropertyManager propertyManager;
  void listener() {
    setState(() {});
  }

  void setPropertyName(String name) {
    if (propertyManager?.name == name) {
      return;
    }
    // forget the old manager
    propertyManager?.removeListener(listener);
    // get the new manager
    propertyManager = RegistryProvider.of(context).getPropertyManager(name);
    propertyManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).specName.addListener(() => setState(() {
          String specName = SelectionProvider.of(context).specName.value;
          if (specName == null) {
            specName = "";
          }
          String propertyName = specName + "/properties/complexity";
          setPropertyName(propertyName);
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (propertyManager?.value == null) {
      return Card();
    }
    return Row(children: [
      Expanded(
        child: ComplexityCard(propertyManager.value),
      ),
    ]);
  }
}

class ComplexityCard extends StatelessWidget {
  final Property property;
  ComplexityCard(this.property);

  TableRow row(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            value,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Complexity complexity =
        new Complexity.fromBuffer(property.messageValue.value);
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Complexity",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Table(
            border: TableBorder.symmetric(
                inside: BorderSide.none, outside: BorderSide.none),
            columnWidths: {
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
            },
            children: [
              row(context, "Paths", "${complexity.pathCount}"),
              row(context, "Operations",
                  "${complexity.getCount + complexity.postCount + complexity.putCount + complexity.deleteCount}"),
              row(context, "Gets", "${complexity.getCount}"),
              row(context, "Posts", "${complexity.postCount}"),
              row(context, "Puts", "${complexity.putCount}"),
              row(context, "Deletes", "${complexity.deleteCount}"),
              row(context, "Schemas", "${complexity.schemaCount}"),
              row(context, "Schema Properties",
                  "${complexity.schemaPropertyCount}"),
            ],
          ),
        ],
      ),
    );
  }
}
