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
import 'package:flutter/semantics.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../models/selection.dart';
import '../models/property.dart';
import '../components/detail_rows.dart';
import '../service/registry.dart';
import '../components/property_edit.dart';
import '../helpers/extensions.dart';
import 'package:registry/generated/metrics/complexity.pb.dart';
import 'package:registry/generated/metrics/vocabulary.pb.dart';

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
                      TimestampRow("created", property.createTime),
                      TimestampRow("updated", property.updateTime),
                      DetailRow(""),
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

class WordCountListCard extends StatefulWidget {
  final String name;
  final List<WordCount> wordCountList;
  WordCountListCard(this.name, this.wordCountList);

  @override
  WordCountListCardState createState() => WordCountListCardState();
}

class WordCountListCardState extends State<WordCountListCard> {
  final ScrollController controller = ScrollController();

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          width: double.infinity,
          color: Theme.of(context).splashColor,
          child: Text(
            "${widget.name} (${widget.wordCountList.length})",
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemCount: widget.wordCountList.length,
              itemBuilder: (BuildContext context, int index) {
                final wordCount = widget.wordCountList[index];
                return Row(
                  children: [
                    Container(
                      width: 40,
                      child: Text(
                        "${wordCount.count}",
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        wordCount.word,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class VocabularyPropertyCard extends StatelessWidget {
  final Property property;
  final Function selflink;
  VocabularyPropertyCard(this.property, {this.selflink});

  Widget build(BuildContext context) {
    Vocabulary vocabulary =
        new Vocabulary.fromBuffer(property.messageValue.value);
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: property.name.last(1),
            show: selflink,
            edit: null,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: WordCountListCard("schemas", vocabulary.schemas),
                ),
                VerticalDivider(width: 7),
                Expanded(
                  child: WordCountListCard("properties", vocabulary.properties),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: WordCountListCard("operations", vocabulary.operations),
                ),
                VerticalDivider(width: 7),
                Expanded(
                  child: WordCountListCard("parameters", vocabulary.parameters),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
