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
  const SpecOutlineCard({super.key});
  @override
  SpecOutlineCardState createState() => SpecOutlineCardState();
}

class SpecOutlineCardState extends State<SpecOutlineCard> {
  String specName = "";
  SpecManager? specManager;
  List<Entry> data = [];
  Selection? selection;
  final ScrollController scrollController = ScrollController();

  void managerListener() {
    setState(() {
      ApiSpec? spec = specManager?.value;
      if ((spec != null) && (spec.contents.isNotEmpty)) {
        if (spec.mimeType.contains("+gzip")) {
          final bytes = GZipDecoder().decodeBytes(spec.contents);
          String body = const Utf8Codec().decoder.convert(bytes);
          YamlNode? doc = loadYamlNode(body);
          data = parseDoc(doc, 0);
        } else if (spec.mimeType.endsWith("+zip")) {
          data = parseZip(spec.contents);
        } else {
          //body = "";
        }
      }
    });
  }

  void specNameListener() {
    setState(() {
      setSpecName(SelectionProvider.of(context)!.specName.value);
    });
  }

  void setSpecName(String name) {
    if (specManager?.name == name) {
      return;
    }
    // forget the old manager
    specManager?.removeListener(managerListener);
    // get the new manager
    specManager = RegistryProvider.of(context)!.getSpecManager(name);
    specManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.specName.addListener(specNameListener);
    super.didChangeDependencies();
    specNameListener(); // ensure this is called when the widget is created
  }

  @override
  void dispose() {
    selection!.specName.removeListener(specNameListener);
    specManager?.removeListener(managerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (specManager?.value == null) {
      return const Card();
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelNameRow(name: specManager!.value!.filename),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
  final String? label;
  final String? value;
  final List<Entry> children;
}

Widget entryRow(Entry e) {
  if (e.indent < 0) {
    return SimpleCodeView(e.value);
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (e.label != null)
        Expanded(
            child: Container(
                padding: EdgeInsets.zero,
                child: Text(
                  ("  " * e.indent) + e.label!,
                  style: GoogleFonts.inconsolata().copyWith(fontSize: 16),
                ))),
      if (e.value != null)
        Expanded(
            child: Container(
                padding: EdgeInsets.zero,
                child: Text(
                  e.value!,
                  style: GoogleFonts.inconsolata().copyWith(fontSize: 16),
                ))),
    ],
  );
}

// Displays one Entry.
// If the entry has children then it's displayed with an ExpansionTile.
class EntryItem extends StatelessWidget {
  final Entry entry;

  const EntryItem(this.entry, {super.key});

  Widget _buildTiles(BuildContext context, Entry root) {
    if (root.children.isEmpty) {
      return ListTile(
        minVerticalPadding: 0,
        title: entryRow(root),
        contentPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
      );
    }
    List<Widget> children = [];
    for (var child in root.children) {
      children.add(_buildTiles(context, child));
    }
    return ExpansionTile(
      key: PageStorageKey<Entry>(root),
      title: entryRow(root),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(context, entry);
  }
}

List<Entry> parseDoc(YamlNode? doc, int indent) {
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
          entries.add(Entry(indent, node.value as String?, null));
        } else if (node.value is bool) {
          entries
              .add(Entry(indent, node.value as bool ? "true" : "false", null));
        }
      } else if (node is YamlMap) {
        entries.add(Entry(
            indent, "$i", "map[${node.length}]", parseDoc(node, indent + 1)));
      } else if (node is YamlList) {
        entries.add(Entry(
            indent, "$i", "list[${node.length}]", parseDoc(node, indent + 1)));
      } else {
        debugPrint("$node");
      }
      i++;
    }
  }
  return entries;
}

List<Entry> parseZip(List<int> data) {
  List<Entry> entries = [];
  final archive = ZipDecoder().decodeBytes(data);
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      String body;
      try {
        body = const Utf8Codec().decoder.convert(file.content);
      } catch (e) {
        body = "unavailable";
      }
      entries.add(Entry(0, filename, null, parseText(body)));
    }
  }
  return entries;
}

List<Entry> parseText(String text) {
  List<Entry> entries = [];
  entries.add(Entry(-1, null, text));
  return entries;
}

class SimpleCodeView extends StatelessWidget {
  final String? text;
  final rowHeight = 18.0;

  const SimpleCodeView(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text!,
      textAlign: TextAlign.left,
      softWrap: false,
      style: GoogleFonts.inconsolata(color: Colors.grey[800]).copyWith(
        fontSize: 14,
        height: 1.1,
      ),
    );
  }
}
