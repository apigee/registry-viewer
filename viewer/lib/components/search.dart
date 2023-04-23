// Copyright 2023 Google LLC. All Rights Reserved.
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

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/string.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';
import 'package:google_fonts/google_fonts.dart';

// SearchCard is a card that displays search results.
class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  SearchCardState createState() => SearchCardState();
}

class SearchCardState extends State<SearchCard> {
  ObservableString results = ObservableString();

  @override
  Widget build(BuildContext context) {
    int? totalHits;
    Object? json;
    var f = NumberFormat("#.##", "en_US");

    if (results.value != "") {
      json = jsonDecode(results.value);
    }
    return ObservableStringProvider(
      observable: results,
      child: Container(
        color: Theme.of(context).highlightColor,
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FullTextSearchBox("enter search terms"),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "total hits: ${pick(json, 'total_hits').asIntOrNull()}"),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pick(json, 'hits').asListOrEmpty((p0) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(children: [
                                Text(
                                  "(${f.format(p0('score').asDoubleOrThrow())}) ",
                                ),
                                Text(p0('id').asStringOrThrow(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!),
                              ]),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: p0('fragments')
                                    .asMapOrThrow()
                                    .entries
                                    .toList()
                                    .map((entry) {
                                  return Container(
                                    margin: const EdgeInsets.all(15.0),
                                    padding: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blueAccent)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(entry.key,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor)),
                                          RichText(
                                              text: textSpan(
                                                  context, entry.value[0])),
                                        ]),
                                  );
                                }).toList(),
                              ),
                            ]);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void resultsListener() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    results.addListener(resultsListener);
    super.didChangeDependencies();
  }
}

TextSpan textSpan(BuildContext context, String text) {
  final re = RegExp(r'\u001B\[(\d+)m');
  var parts = text.split(re);
  var children = <TextSpan>[];
  for (int i = 1; i < parts.length; i++) {
    if (i % 2 == 0) {
      children.add(TextSpan(text: parts[i]));
    } else {
      children.add(TextSpan(
          text: parts[i],
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold)));
    }
  }
  return TextSpan(
    text: parts[0],
    style:
        GoogleFonts.inconsolata().copyWith(fontSize: 20, color: Colors.black),
    children: children,
  );
}

// FullTextSearchBox provides a search box.
class FullTextSearchBox extends StatefulWidget {
  final String hintText;
  const FullTextSearchBox(this.hintText, {super.key});

  @override
  FullTextSearchBoxState createState() => FullTextSearchBoxState();
}

class FullTextSearchBoxState extends State<FullTextSearchBox> {
  final searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        0,
        8,
        0,
        8,
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: searchTextController,
        decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.black),
            suffixIcon: ExcludeFocus(
              child: IconButton(
                color: Colors.black,
                icon: const Icon(Icons.clear),
                tooltip: "Clear",
                onPressed: () {
                  searchTextController.clear();
                },
              ),
            ),
            border: InputBorder.none,
            hintText: widget.hintText),
        onSubmitted: (s) {
          fetch(s, ObservableStringProvider.of(context));
        },
      ),
    );
  }
}

void fetch(String query, ObservableString? results) async {
  var url = Uri.https('sierra.timbx.me', '/search', {'q': query});
  var response = await http.get(url);
  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');
  results?.value = response.body;
}

class SearchResults {
  SearchResults({required this.totalHits, required this.maxScore});
  final int totalHits;
  final double maxScore;

  factory SearchResults.fromJson(Map<String, dynamic> data) {
    final totalHits = data['total_hits'] as int;

    double maxScore;
    try {
      maxScore = data['max_score'] as double;
    } catch (e) {
      maxScore = (data['max_score'] as int).toDouble();
    }

    return SearchResults(totalHits: totalHits, maxScore: maxScore);
  }
}
