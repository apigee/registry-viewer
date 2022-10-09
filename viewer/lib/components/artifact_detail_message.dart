// Copyright 2022 Google LLC. All Rights Reserved.
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:registry/registry.dart';
import 'detail_rows.dart';
import '../helpers/extensions.dart';
import 'package:yaml/yaml.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:protobuf/protobuf.dart';

class MessageArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final GeneratedMessage message;
  final Function? selflink;
  MessageArtifactCard(this.artifact, this.message, {this.selflink});
  List<Entry> data = [];
  final ScrollController scrollController = ScrollController();

  Widget build(BuildContext context) {
    String json = jsonEncode(message.toProto3Json());
    YamlNode doc = loadYamlNode(json);
    data = parseDoc(doc, 0);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: artifact.name.last(1),
            show: selflink as void Function()?,
            edit: null,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              width: double.infinity,
              child: Scrollbar(
                controller: scrollController,
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  itemBuilder: (BuildContext context, int index) =>
                      EntryItem(data[index]),
                  itemCount: data.length,
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

// One entry in the multilevel list displayed by this app.
class Entry {
  Entry(this.indent, this.label, this.value, [this.children = const <Entry>[]]);
  final int indent;
  final String? label;
  final String value;
  final List<Entry> children;
}

Container entryRow(Entry e) {
  return Container(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Container(
                padding: EdgeInsets.zero,
                child: Text(
                  ("  " * e.indent) + e.label!,
                  style: GoogleFonts.inconsolata().copyWith(fontSize: 16),
                ))),
        Expanded(
            child: Container(
                padding: EdgeInsets.zero,
                child: Text(
                  e.value,
                  style: GoogleFonts.inconsolata().copyWith(fontSize: 16),
                ))),
      ],
    ),
  );
}

// Displays one Entry.
// If the entry has children then it's displayed with an ExpansionTile.
class EntryItem extends StatelessWidget {
  final Entry entry;

  const EntryItem(this.entry);

  Widget _buildTiles(BuildContext context, Entry root) {
    if (root.children.isEmpty)
      return ListTile(
        minVerticalPadding: 0,
        title: entryRow(root),
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      );

    List<Widget> children = [];
    for (var child in root.children) {
      children.add(_buildTiles(context, child));
    }
    return ExpansionTile(
      //backgroundColor: Theme.of(context).accentColor,
      //collapsedBackgroundColor: Theme.of(context).highlightColor,
      key: PageStorageKey<Entry>(root),
      title: entryRow(root),
      children: children,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(context, entry);
  }
}

List<Entry> parseDoc(YamlNode doc, int indent) {
  List<Entry> entries = [];
  if (doc is YamlMap) {
    for (var key in doc.keys) {
      var node = doc[key];
      if (node is String) {
        entries.add(Entry(indent, key, node));
      } else if (node is bool) {
        entries.add(Entry(indent, key, node ? "true" : "false"));
      } else if (node is YamlMap) {
        entries.add(Entry(
            indent, key, "map[${node.length}]", parseDoc(node, indent + 1)));
      } else if (node is YamlList) {
        entries.add(Entry(
            indent, key, "list[${node.length}]", parseDoc(node, indent + 1)));
      }
    }
  } else if (doc is YamlList) {
    var i = 0;
    for (var node in doc.nodes) {
      if (node is YamlScalar) {
        if (node.value is String) {
          entries.add(Entry(indent, node.value as String?, ""));
        } else if (node.value is bool) {
          entries.add(Entry(indent, node.value as bool ? "true" : "false", ""));
        }
      } else if (node is YamlMap) {
        entries.add(Entry(
            indent, "$i", "map[${node.length}]", parseDoc(node, indent + 1)));
      } else if (node is YamlList) {
        entries.add(Entry(
            indent, "$i", "list[${node.length}]", parseDoc(node, indent + 1)));
      } else {
        print(node);
      }
      i++;
    }
  }
  return entries;
}
