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

import 'package:flutter/material.dart';
import 'package:registry/registry.dart';
import 'detail_rows.dart';
import '../helpers/extensions.dart';

class ScoreCardArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final Function? selflink;
  const ScoreCardArtifactCard(this.artifact, {this.selflink, super.key});

  @override
  Widget build(BuildContext context) {
    ScoreCard scoreCard = ScoreCard.fromBuffer(artifact.contents);
    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
            name: artifact.name.last(1),
            show: selflink as void Function()?,
            edit: null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scoreCard.displayName,
                      style: Theme.of(context).textTheme.titleMedium!),
                  Text(scoreCard.description),
                  Expanded(
                    child: GridView.builder(
                      itemCount:
                          scoreCard.scores.length, // The length Of the array
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ), // The size of the grid box
                      itemBuilder: (context, index) => Container(
                        color: Colors.white,
                        child: Container(
                          margin: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(scoreCard.scores[index].displayName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium!),
                              Text(
                                  "${scoreCard.scores[index].integerValue.value}",
                                  style:
                                      Theme.of(context).textTheme.titleLarge!),
                              Text(scoreCard.scores[index].description),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
