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
import '../components/property_detail_complexity.dart';
import '../components/property_detail_string.dart';
import '../components/property_detail_vocabulary.dart';
import '../helpers/extensions.dart';
import '../models/property.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// PropertyDetailCard is a card that displays details about a property.
class PropertyDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  PropertyDetailCard({this.selflink, this.editable});
  _PropertyDetailCardState createState() => _PropertyDetailCardState();
}

class _PropertyDetailCardState extends State<PropertyDetailCard> {
  PropertyManager propertyManager;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context).propertyName.value);
    });
  }

  void setProjectName(String name) {
    if (propertyManager?.name == name) {
      return;
    }
    // forget the old manager
    propertyManager?.removeListener(managerListener);
    // get the new manager
    propertyManager = RegistryProvider.of(context).getPropertyManager(name);
    propertyManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).propertyName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    propertyManager?.removeListener(managerListener);
    SelectionProvider.of(context)
        .propertyName
        .removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Property property = propertyManager?.value;
      Navigator.pushNamed(
        context,
        property.routeNameForDetail(),
      );
    });

    if (propertyManager?.value == null) {
      return Card(
        child: Container(
          color: Colors.grey[200],
        ),
      );
    } else {
      Property property = propertyManager.value;

      if (property.hasMessageValue()) {
        switch (property.messageValue.typeUrl) {
          case "gnostic.metrics.Complexity":
            return ComplexityPropertyCard(property, selflink: selflink);
          case "gnostic.metrics.Vocabulary":
            return VocabularyPropertyCard(property, selflink: selflink);
        }
        // if we don't recognize this message, clear it out to not overflow the display
        property.messageValue.value = List();
      }

      if (property.hasStringValue()) {
        return StringPropertyCard(
          property,
          selflink: selflink,
          editable: widget.editable,
        );
      }

      // otherwise return a default display of the property
      return DefaultPropertyDetailCard();
    }
  }
}

// DefaultPropertyDetailCard is a card that displays details about a property.
class DefaultPropertyDetailCard extends StatefulWidget {
  DefaultPropertyDetailCard();
  _DefaultPropertyDetailCardState createState() =>
      _DefaultPropertyDetailCardState();
}

class _DefaultPropertyDetailCardState extends State<DefaultPropertyDetailCard> {
  PropertyManager propertyManager;
  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setProjectName(SelectionProvider.of(context).propertyName.value);
    });
  }

  void setProjectName(String name) {
    if (propertyManager?.name == name) {
      return;
    }
    // forget the old manager
    propertyManager?.removeListener(managerListener);
    // get the new manager
    propertyManager = RegistryProvider.of(context).getPropertyManager(name);
    propertyManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).propertyName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    propertyManager?.removeListener(managerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Property property = propertyManager?.value;
    if (property == null) {
      return Card();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
              name: property.name.last(1), show: null, edit: null),
          Expanded(
            child: Scrollbar(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      TimestampRow(property.createTime, property.updateTime),
                      DetailRow("$property"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
