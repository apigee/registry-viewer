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
import '../models/string.dart';

// CustomSearchBox provides a search box for projects.
class CustomSearchBox extends StatefulWidget {
  final String hintText;
  final String filterText;
  const CustomSearchBox(this.hintText, this.filterText, {super.key});

  @override
  CustomSearchBoxState createState() => CustomSearchBoxState();
}

class CustomSearchBoxState extends State<CustomSearchBox> {
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
            suffixIcon: IconButton(
              color: Colors.black,
              icon: const Icon(Icons.clear),
              tooltip: "Clear",
              onPressed: () {
                searchTextController.clear();
                ObservableStringProvider.of(context)!.update("");
              },
            ),
            border: InputBorder.none,
            hintText: widget.hintText),
        onSubmitted: (s) {
          ObservableString? filter = ObservableStringProvider.of(context);
          if (filter != null) {
            if (s == "") {
              filter.update(""); // no filter specified
            } else if (s[0] == "=") {
              filter.update(s.substring(1)); // filter is a CEL expression
            } else {
              // use configured string with user-provided text
              filter.update(widget.filterText.replaceAll("TEXT", s));
            }
          }
        },
      ),
    );
  }
}
