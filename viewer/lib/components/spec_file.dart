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
import 'package:google_fonts/google_fonts.dart';
import 'package:registry/registry.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/renderer.dart';
import '../components/detail_rows.dart';
import '../helpers/measure_size.dart';
import '../models/highlight.dart';
import '../models/selection.dart';
import '../service/registry.dart';
import '../components/split_view.dart';

const scrollDuration = Duration(milliseconds: 300);
const scrollCurve = Curves.easeInOut;

// An item in a spec file (a file in a zip archive).
class Item {
  Item({
    this.expandedValue,
    this.headerValue,
  });

  String? expandedValue;
  String? headerValue;
}

// SpecFileCard is a card that displays the text of a spec.
class SpecFileCard extends StatefulWidget {
  const SpecFileCard({super.key});
  @override
  SpecFileCardState createState() => SpecFileCardState();
}

class SpecFileCardState extends State<SpecFileCard> {
  String specName = "";
  SpecManager? specManager;
  String body = "";
  List<Item>? items;
  int selectedItemIndex = 0;
  Selection? selection;
  final ScrollController listScrollController = ScrollController();
  final ScrollController fileScrollController = ScrollController();
  final rowHeight = 40.0;
  late double listHeight;

  void managerListener() {
    setState(() {
      ApiSpec? spec = specManager?.value;
      if ((spec != null) && (spec.contents.isNotEmpty)) {
        if (spec.mimeType.contains("+gzip")) {
          final data = GZipDecoder().decodeBytes(spec.contents);
          body = const Utf8Codec().decoder.convert(data);
        } else if (spec.mimeType.endsWith("+zip")) {
          items = [];
          final archive = ZipDecoder().decodeBytes(spec.contents);
          for (final file in archive) {
            final filename = file.name;
            if (file.isFile) {
              String body;
              try {
                body = const Utf8Codec().decoder.convert(file.content);
              } catch (e) {
                body = "unavailable";
              }
              Item item = Item(headerValue: filename, expandedValue: body);
              items!.add(item);
            }
          }
        } else {
          body = "";
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

  void fileNameListener() {
    setState(() {
      setFileName(SelectionProvider.of(context)!.fileName.value);
    });
  }

  bool isVisible(int index) {
    final listOffset = listScrollController.offset;
    final firstIndex = listOffset / rowHeight;
    if (firstIndex > index) {
      return false;
    }
    final lastIndex = (listOffset + listHeight) / rowHeight - 1;
    if (index > lastIndex) {
      return false;
    }
    return true;
  }

  void setFileName(String name) {
    if (name == "") {
      return;
    }
    if (items != null) {
      for (int i = 0; i < items!.length; i++) {
        if (items![i].headerValue == name) {
          selectedItemIndex = i;
          // if the item is off screen, animate it into position
          if (!isVisible(selectedItemIndex)) {
            listScrollController.animateTo(
              rowHeight * (selectedItemIndex - 2.5),
              duration: scrollDuration,
              curve: scrollCurve,
            );
          }
          return;
        }
      }
    }
    selectedItemIndex = -1;
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.specName.addListener(specNameListener);
    selection!.fileName.addListener(fileNameListener);
    super.didChangeDependencies();
    specNameListener();
    fileNameListener();
  }

  @override
  void dispose() {
    selection!.fileName.removeListener(fileNameListener);
    selection!.specName.removeListener(specNameListener);
    specManager?.removeListener(managerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (specManager?.value == null) {
      return const Card();
    } else {
      if (items == null) {
        // single-file view
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelNameRow(
                name: specManager!.value!.filename,
                button: IconButton(
                  color: Colors.black,
                  icon: const Icon(Icons.open_in_new),
                  tooltip: "Viewer",
                  onPressed: () {
                    var address = rendererServiceAddress();
                    if ((address != "SPEC_RENDERER_SERVICE") &&
                        (address != "")) {
                      launchUrl(
                          Uri.parse("$address/${specManager!.value!.name}"));
                    } else {
                      AlertDialog alert = AlertDialog(
                        content:
                            const Text("Spec renderer service not configured"),
                        actions: [
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop(); // dismiss dialog
                            },
                          ),
                        ],
                      );
                      // show the dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        },
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: CodeView(body),
                ),
              ),
            ],
          ),
        );
      } else {
        // multi-file view
        return CustomSplitView(
          viewMode: SplitViewMode.Vertical,
          initialWeight: 0.25,
          view1: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Scrollbar(
                      controller: listScrollController,
                      thumbVisibility: true,
                      child: MeasureSize(
                        onChange: (size) {
                          listHeight = size.height;
                        },
                        child: ListView.builder(
                          itemCount: items!.length,
                          controller: listScrollController,
                          itemBuilder: (BuildContext context, int index) {
                            String fileName = items![index].headerValue!;

                            Color? color = (index != selectedItemIndex)
                                ? Theme.of(context).textTheme.bodyLarge!.color
                                : Theme.of(context).primaryColor;

                            return GestureDetector(
                              child: Container(
                                color: (index == selectedItemIndex)
                                    ? color!.withAlpha(64)
                                    : Theme.of(context).canvasColor,
                                height: rowHeight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      fileName,
                                      softWrap: false,
                                      style: GoogleFonts.inconsolata()
                                          .copyWith(color: color),
                                      overflow: TextOverflow.clip,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                selection!.fileName.update(fileName);
                                selection!.highlight.update(null);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          view2: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: CodeView(items![selectedItemIndex].expandedValue),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}

class CodeView extends StatefulWidget {
  final String? text;
  const CodeView(this.text, {super.key});
  @override
  CodeViewState createState() => CodeViewState();
}

class CodeViewState extends State<CodeView> {
  late List<String> lines;
  ScrollController scrollController = ScrollController();
  Highlight? highlight = Highlight(-1, -1, -1, -1);
  Selection? selection;
  final rowHeight = 18.0;

  void highlightListener() {
    setState(() {
      highlight = SelectionProvider.of(context)!.highlight.value;
      if (highlight == null) {
        highlight = Highlight(-1, -1, -1, -1);
      } else {
        scrollController.animateTo(
          (highlight!.startRow - 4) * rowHeight,
          duration: scrollDuration,
          curve: scrollCurve,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.highlight.addListener(highlightListener);
    super.didChangeDependencies();
    highlightListener();
  }

  @override
  void dispose() {
    selection!.highlight.removeListener(highlightListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    lines = splitLines(widget.text!);
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        itemBuilder: (context, i) {
          return rowForText(i, lines[i]);
        },
        itemCount: lines.length,
        controller: scrollController,
      ),
    );
  }

  Widget rowForText(int i, String line) {
    List<Widget> children = [];
    children.add(SizedBox(
        width: 50,
        child: Text(
          "${i + 1}",
          textAlign: TextAlign.right,
          style: GoogleFonts.inconsolata(color: Colors.grey[500]),
        )));
    children.add(const SizedBox(width: 10));
    String before = "";
    String middle = "";
    String after = "";
    if (i < highlight!.startRow) {
      before = line;
    } else if (i == highlight!.startRow) {
      before = line.substring(0, highlight!.startCol);
      if (i == highlight!.endRow) {
        middle = line.substring(highlight!.startCol, highlight!.endCol + 1);
        after = line.substring(highlight!.endCol + 1);
      } else {
        middle = line.substring(highlight!.startCol);
      }
    } else if (i < highlight!.endRow) {
      middle = line;
    } else if (i == highlight!.endRow) {
      middle = line.substring(0, highlight!.endCol + 1);
      after = line.substring(highlight!.endCol + 1);
    } else {
      after = line;
    }
    Paint backgroundColor = Paint();
    backgroundColor.color = Theme.of(context).primaryColor.withAlpha(64);
    children.add(
      Flexible(
        child: RichText(
          overflow: TextOverflow.clip,
          text: TextSpan(
            text: before,
            style: GoogleFonts.inconsolata(color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                text: middle,
                style: GoogleFonts.inconsolata(
                  color: Theme.of(context).primaryColor,
                  background: backgroundColor,
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        ),
      ),
    );
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: children,
      ),
    );
  }

  List<String> splitLines(String text) {
    return text.split("\n");
  }
}
