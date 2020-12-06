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
class CustomSearchBox extends StatelessWidget {
  final String hintText;
  final String filterText;

  CustomSearchBox(this.hintText, this.filterText);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        8,
      ),
      alignment: Alignment.centerLeft,
      color: Theme.of(context).secondaryHeaderColor,
      child: TextField(
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: Colors.black),
            border: InputBorder.none,
            hintText: hintText),
        onSubmitted: (s) {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            if (s == "") {
              filter.update("");
            } else {
              filter.update(filterText.replaceAll("TEXT", "$s"));
            }
          }
        },
      ),
    );
  }
}
