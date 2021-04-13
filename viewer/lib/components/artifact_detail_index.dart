// Copyright 2021 Google LLC. All Rights Reserved.
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
import 'package:registry/registry.dart';
import 'detail_rows.dart';
import '../helpers/extensions.dart';

class IndexArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final Function selflink;
  IndexArtifactCard(this.artifact, {this.selflink});

  Widget build(BuildContext context) {
    Index index = new Index.fromBuffer(artifact.contents);
    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
            name: artifact.name.last(1),
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
                        row(context, "Files", "${index.files.length}"),
                        row(context, "Operations",
                            "${index.operations.length}"),
                        row(context, "Fields", "${index.fields.length}"),
                        row(context, "Schemas", "${index.schemas.length}"),
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
