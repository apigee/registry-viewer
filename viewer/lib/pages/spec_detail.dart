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
import '../models/selection.dart';
import '../components/spec_detail.dart';
import '../components/artifact_list.dart';
import '../components/spec_file.dart';
import '../components/artifact_detail.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';

class SpecDetailPage extends StatelessWidget {
  final String name;
  SpecDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      selection
          .updateApiName(name.substring(1).split("/").sublist(0, 4).join("/"));
      selection.updateVersionName(
          name.substring(1).split("/").sublist(0, 6).join("/"));
      selection.updateSpecName(name.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Spec Details",
          ),
          actions: <Widget>[
            homeButton(context),
          ],
        ),
        body: Column(children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: SpecDetailCard(editable: true)),
                Expanded(child: ArtifactListCard(SelectionProvider.spec)),
                Expanded(
                  child: ArtifactDetailCard(
                    selflink: true,
                    editable: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: SpecFileCard(),
                ),
              ],
            ),
          ),
          BottomBar(),
        ]),
      ),
    );
  }
}
