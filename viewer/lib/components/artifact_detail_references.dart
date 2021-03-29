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
import 'package:registry/registry.dart';
import '../components/detail_rows.dart';
import '../helpers/extensions.dart';

class ReferencesArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final Function selflink;
  ReferencesArtifactCard(this.artifact, {this.selflink});

  Widget build(BuildContext context) {
    References references = new References.fromBuffer(artifact.contents);
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: artifact.name.last(1),
            show: selflink,
            edit: null,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child:
                      WordListCard("externals", references.externalReferences),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child:
                      WordListCard("available", references.availableReferences),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WordListCard extends StatefulWidget {
  final String name;
  final List<String> wordList;
  WordListCard(this.name, this.wordList);

  @override
  WordListCardState createState() => WordListCardState();
}

class WordListCardState extends State<WordListCard> {
  final ScrollController controller = ScrollController();

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
          width: double.infinity,
          color: Theme.of(context).splashColor,
          child: Text(
            "${widget.name} (${widget.wordList.length})",
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemCount: widget.wordList.length,
              itemBuilder: (BuildContext context, int index) {
                final word = widget.wordList[index];
                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        word,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
