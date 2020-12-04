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
import '../models/selection.dart';
import '../models/property.dart';
import 'detail_rows.dart';
import '../service/registry.dart';
import '../components/property_edit.dart';
import '../helpers/extensions.dart';

// PropertyDetailCard is a card that displays details about a property.
class PropertyDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  PropertyDetailCard({this.selflink, this.editable});
  _PropertyDetailCardState createState() => _PropertyDetailCardState();
}

class _PropertyDetailCardState extends State<PropertyDetailCard> {
  PropertyManager propertyManager;
  void listener() {
    setState(() {});
  }

  void setProjectName(String name) {
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
    SelectionProvider.of(context).propertyName.addListener(() {
      setState(() {
        setProjectName(SelectionProvider.of(context).propertyName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Property property = propertyManager?.value;
      Navigator.pushNamed(
        context,
        property.routeNameForDetail(),
        arguments: property,
      );
    });

    Function editable = onlyIf(widget.editable, () {
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

    if (propertyManager?.value == null) {
      return Card(child: Center(child: Text("select a property")));
    } else {
      Property property = propertyManager.value;
      return Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResourceNameButtonRow(
                          name: property.name.last(1),
                          show: selflink,
                          edit: editable),
                      SizedBox(height: 10),
                      TimestampRow("created", property.createTime),
                      TimestampRow("updated", property.updateTime),
                      DetailRow(""),
                      DetailRow("$property"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
