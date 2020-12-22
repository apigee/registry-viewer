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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:registry/generated/metrics/complexity.pb.dart';
import '../components/detail_rows.dart';
import '../helpers/extensions.dart';

class ComplexityPropertyCard extends StatelessWidget {
  final Property property;
  final Function selflink;
  ComplexityPropertyCard(this.property, {this.selflink});

  Widget build(BuildContext context) {
    Complexity complexity =
        new Complexity.fromBuffer(property.messageValue.value);
    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
            name: property.name.last(1),
            show: selflink,
            edit: null,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Table(
                      border: TableBorder.symmetric(
                          inside: BorderSide.none, outside: BorderSide.none),
                      columnWidths: {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
