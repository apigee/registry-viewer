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
import '../service/service.dart';
import '../models/observable.dart';

// PropertiesCard
typedef ObservableStringProvider = ObservableString Function(
    BuildContext context);

class PropertiesCard extends StatefulWidget {
  final ObservableStringProvider getObservableResourceName;
  PropertiesCard(this.getObservableResourceName);

  @override
  _PropertiesCardState createState() => _PropertiesCardState();
}

class _PropertiesCardState extends State<PropertiesCard> {
  String subjectName;
  List<Property> properties;

  String projectName() {
    return subjectName.split("/").sublist(0, 2).join("/");
  }

  @override
  void didChangeDependencies() {
    widget.getObservableResourceName(context).addListener(() => setState(() {
          subjectName = widget.getObservableResourceName(context).value;
          if (subjectName == null) {
            subjectName = "";
          }
          this.properties = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (subjectName == null) {
      return Card(child: Center(child: Text("no subject")));
    }
    if (properties == null) {
      // we need to fetch the properties from the API
      PropertiesService.listProperties(projectName(), subject: subjectName)
          .then((properties) {
        setState(() {
          this.properties = properties.properties;
        });
      });
      return Card(child: Center(child: Text("loading")));
    }
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Properties",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Table(
              columnWidths: {
                0: IntrinsicColumnWidth(),
              },
              children: properties.map(
                (property) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          property.relation,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  );
                },
              ).toList()),
        ],
      ),
    );
  }
}
