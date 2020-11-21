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
import '../models/selection.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

// SpecFileCard is a card that displays the text of a spec.
class SpecFileCard extends StatefulWidget {
  _SpecFileCardState createState() => _SpecFileCardState();
}

class _SpecFileCardState extends State<SpecFileCard> {
  String specName = "";
  Spec spec;
  String body;
  List<Item> items;

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).spec.addListener(() => setState(() {
          specName = SelectionProvider.of(context).spec.value;
          if (specName == null) {
            specName = "";
          }
          this.spec = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (spec == null) {
      if (specName != "") {
        // we need to fetch the spec from the API
        SpecService().getSpec(specName).then((spec) {
          setState(() {
            if ((spec.contents != null) && (spec.contents.length > 0)) {
              if (spec.style.endsWith("+gzip")) {
                final data = GZipDecoder().decodeBytes(spec.contents);
                this.body = Utf8Codec().decoder.convert(data);
              } else if (spec.style.endsWith("+zip")) {
                this.items = List();
                final archive = ZipDecoder().decodeBytes(spec.contents);
                for (final file in archive) {
                  final filename = file.name;
                  if (file.isFile) {
                    String body;
                    try {
                      body = String.fromCharCodes(file.content);
                    } catch (e) {
                      body = "unavailable";
                    }
                    Item item =
                        Item(headerValue: filename, expandedValue: body);
                    items.add(item);
                  }
                }
              } else {
                this.body = "";
              }
            }
            this.spec = spec;
          });
        });
      }
      return Card();
    } else {
      if (this.items == null) {
        return Card(
          child: SingleChildScrollView(
            child: Text(body),
          ),
        );
      } else {
        return Card(
          child: MyStatefulWidget(items: items),
        );
      }
    }
  }
}

// stores ExpansionPanel state information
class Item {
  Item({
    this.expandedValue,
    this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

List<Item> generateItems(int numberOfItems) {
  return List.generate(numberOfItems, (int index) {
    return Item(
      headerValue: 'Panel $index',
      expandedValue: 'This is item number $index',
    );
  });
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  final List<Item> items;

  MyStatefulWidget({Key key, List<Item> items})
      : items = items,
        super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState(items);
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  List<Item> _data;

  _MyStatefulWidgetState(this._data);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [_buildPanel()],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _data[index].isExpanded = !isExpanded;
        });
      },
      children: _data.map<ExpansionPanel>((Item item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(item.headerValue),
            );
          },
          body: ListTile(
            title: Text(item.expandedValue),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}
