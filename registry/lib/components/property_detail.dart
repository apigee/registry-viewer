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
import '../models/selection.dart';
import '../models/property.dart';
import '../components/detail_rows.dart';
import '../service/registry.dart';
import '../components/property_edit.dart';
import '../helpers/extensions.dart';
import 'package:registry/generated/metrics/complexity.pb.dart';

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

      if (property.hasMessageValue()) {
        final messageValue = property.messageValue;

        switch (messageValue.typeUrl) {
          case "gnostic.metrics.Complexity":
            return complexityCard(property);
        }

        property.messageValue.value = List();
      }

      if (property.hasStringValue()) {
        return stringCard(property);
      }

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

  Widget stringCard(Property property) {
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

    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            ResourceNameButtonRow(
                name: property.name.last(1), show: null, edit: editable),
            SizedBox(height: 40),
            BodyRow(property.stringValue),
          ],
        ),
      ),
    );
  }

  Widget complexityCard(Property property) {
    Complexity complexity =
        new Complexity.fromBuffer(property.messageValue.value);
    return Card(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
