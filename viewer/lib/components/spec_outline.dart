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

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/registry.dart';
import 'package:registry/registry.dart';
import '../models/selection.dart';
import '../components/detail_rows.dart';

// SpecOutlineCard displays an outline view of a spec.
class SpecOutlineCard extends StatefulWidget {
  _SpecOutlineCardState createState() => _SpecOutlineCardState();
}

class _SpecOutlineCardState extends State<SpecOutlineCard> {
  String specName = "";
  SpecManager specManager;
  List<Entry> data = [];
  String body = "";
  YamlNode doc;
  Selection selection;
  final ScrollController scrollController = ScrollController();

  void managerListener() {
    setState(() {
      ApiSpec spec = specManager?.value;
      if ((spec != null) &&
          (spec.contents != null) &&
          (spec.contents.length > 0)) {
        if (spec.mimeType.contains("+gzip")) {
          final bytes = GZipDecoder().decodeBytes(spec.contents);
          this.body = Utf8Codec().decoder.convert(bytes);
          doc = loadYamlNode(this.body);
          data = parseDoc(doc, 0);
        } else if (spec.mimeType.endsWith("+zip")) {
          this.body = "";
        } else {
          this.body = "";
        }
      }
    });
  }

  void specNameListener() {
    setState(() {
      setSpecName(SelectionProvider.of(context).specName.value);
    });
  }

  void setSpecName(String name) {
    if (specManager?.name == name) {
      return;
    }
    // forget the old manager
    specManager?.removeListener(managerListener);
    // get the new manager
    specManager = RegistryProvider.of(context).getSpecManager(name);
    specManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.specName.addListener(specNameListener);
    super.didChangeDependencies();
    specNameListener(); // ensure this is called when the widget is created
  }

  @override
  void dispose() {
    selection.specName.removeListener(specNameListener);
    specManager?.removeListener(managerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((specManager?.value == null) || (this.body == "")) {
      return Card();
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelNameRow(name: specManager.value.filename + " (outline)"),
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
}

// One entry in the multilevel list displayed by this app.
class Entry {
  Entry(this.indent, this.label, this.value, [this.children = const <Entry>[]]);
  final int indent;
  final String label;
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
                  ("  " * e.indent) + e.label,
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
          entries.add(Entry(indent, node.value as String, ""));
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
