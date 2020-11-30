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
// See the License for the projectific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:catalog/generated/metrics/complexity.pb.dart';
import '../service/service.dart';
import '../models/selection.dart';

// ProjectPropertiesCard

class ProjectPropertiesCard extends StatefulWidget {
  @override
  _ProjectPropertiesCardState createState() => _ProjectPropertiesCardState();
}

class _ProjectPropertiesCardState extends State<ProjectPropertiesCard> {
  String projectName;
  List<Property> properties;
  _ProjectPropertiesCardState();

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).projectName.addListener(() => setState(() {
          projectName = SelectionProvider.of(context).projectName.value;
          if (projectName == null) {
            projectName = "";
          }
          this.properties = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (projectName == null) {
      return Card();
    }
    if (properties == null) {
      // we need to fetch the properties from the API
      final propertiesFuture =
          PropertiesService.listProperties(projectName, subject: projectName);
      propertiesFuture.then((properties) {
        setState(() {
          this.properties = properties.properties;
        });
      });
      return Card();
    }
    if (propertiesContain(properties, "complexity")) {
      return Row(children: [
        summaryCard(context, properties),
      ]);
    }
    return Card();
  }
}

bool propertiesContain(List<Property> properties, String propertyName) {
  if (properties == null) {
    return false;
  }
  for (var p in properties) {
    if (p.relation == propertyName) return true;
  }
  return false;
}

Property propertyWithName(List<Property> properties, String propertyName) {
  if (properties == null) {
    return null;
  }
  for (var p in properties) {
    if (p.relation == propertyName) return p;
  }
  return null;
}

TableRow row(BuildContext context, String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: EdgeInsets.all(5),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(5),
        child: Text(
          value,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

Expanded summaryCard(BuildContext context, List<Property> properties) {
  final summary = propertyWithName(properties, "complexity");
  Complexity complexitySummary =
      new Complexity.fromBuffer(summary.messageValue.value);
  print("complexity $summary");
  return Expanded(
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: SizedBox()),
              Expanded(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    //TableRow(children: [Text("Objects")]),
                    row(context, "Paths", "${complexitySummary.pathCount}"),
                    row(context, "Schemas", "${complexitySummary.schemaCount}"),
                    row(context, "Schema Properties",
                        "${complexitySummary.schemaPropertyCount}"),
                  ],
                ),
              ),
              Expanded(child: SizedBox()),
              Expanded(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    // TableRow(children: [Text("Operations")]),
                    row(context, "Operations",
                        "${complexitySummary.getCount + complexitySummary.postCount + complexitySummary.putCount + complexitySummary.deleteCount}"),
                    row(context, "GETs", "${complexitySummary.getCount}"),
                    row(context, "POSTs", "${complexitySummary.postCount}"),
                    row(context, "PUTs", "${complexitySummary.putCount}"),
                    row(context, "DELETEs", "${complexitySummary.deleteCount}"),
                  ],
                ),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    ),
  );
}
