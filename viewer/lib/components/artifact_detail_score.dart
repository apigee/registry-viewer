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

class ScoreArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final Function? selflink;
  const ScoreArtifactCard(this.artifact, {this.selflink, super.key});

  @override
  Widget build(BuildContext context) {
    Score score = Score.fromBuffer(artifact.contents);
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(score.displayName,
                      style: Theme.of(context).textTheme.titleMedium!),
                  Text("${score.integerValue.value}",
                      style: Theme.of(context).textTheme.titleLarge!),
                  Text(score.description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
