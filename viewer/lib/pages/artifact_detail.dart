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
import '../components/artifact_detail.dart';
import '../components/bottom_bar.dart';
import '../components/home_button.dart';
import '../helpers/title.dart';

class ArtifactDetailPage extends StatelessWidget {
  final String? name;
  const ArtifactDetailPage({this.name});

  @override
  Widget build(BuildContext context) {
    final Selection selection = Selection();

    Future.delayed(const Duration(), () {
      List parts = name!.split("/");
      parts.insert(3, "global");
      parts.insert(3, "locations");
      String name2 = parts.join("/");
      selection.updateArtifactName(name2.substring(1));
    });

    return SelectionProvider(
      selection: selection,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(pageTitle(name) ?? "Artifact Details"),
          actions: <Widget>[
            homeButton(context),
          ],
        ),
        body: Column(
          children: [
            const Expanded(
              child: ArtifactDetailCard(editable: true),
            ),
            BottomBar(),
          ],
        ),
      ),
    );
  }
}
