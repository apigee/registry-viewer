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
import '../components/detail_rows.dart';
import '../components/property_edit.dart';
import '../helpers/extensions.dart';
import '../models/selection.dart';

class StringPropertyCard extends StatelessWidget {
  final Property property;
  final Function selflink;
  final bool editable;
  StringPropertyCard(this.property, {this.selflink, this.editable});
  @override
  Widget build(BuildContext context) {
    Function editableFn = onlyIf(editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: EditPropertyForm(),
              ),
            );
          });
    });

    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
              name: property.name.last(1), show: selflink, edit: editableFn),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                SizedBox(height: 30),
                BodyRow(property.stringValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
