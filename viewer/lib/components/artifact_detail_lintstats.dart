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
import 'package:url_launcher/url_launcher.dart';
import 'detail_rows.dart';
import '../helpers/extensions.dart';

String stringForLocation(LintLocation location) {
  return "[${location.startPosition.lineNumber}:" +
      "${location.startPosition.columnNumber}-" +
      "${location.endPosition.lineNumber}:" +
      "${location.endPosition.columnNumber}]";
}

class LintStatsArtifactCard extends StatefulWidget {
  final Artifact artifact;
  final Function? selflink;
  const LintStatsArtifactCard(this.artifact, {this.selflink});

  @override
  LintStatsArtifactCardState createState() => LintStatsArtifactCardState();
}

class LintStatsArtifactCardState extends State<LintStatsArtifactCard> {
  LintStats? lintstats;
  final ScrollController controller = ScrollController();
  int selectedIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lintstats == null) {
      lintstats = LintStats.fromBuffer(widget.artifact.contents);
    }
    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
            name: widget.artifact.name.last(1),
            show: widget.selflink as void Function()?,
            edit: null,
          ),
          Expanded(
            child: Scrollbar(
              controller: controller,
              child: ListView.builder(
                controller: controller,
                itemCount: lintstats?.problemCounts.length,
                itemBuilder: (BuildContext context, int index) {
                  if (lintstats == null) {
                    return Container();
                  }
                  final problemCount = lintstats!.problemCounts[index];
                  return GestureDetector(
                    onTap: () {
                      selectedIndex = index;
                      setState(() {});
                    },
                    child: Card(
                      child: Container(
                        color: (selectedIndex == index)
                            ? Theme.of(context).primaryColor.withAlpha(64)
                            : Theme.of(context).canvasColor,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  child: Text(problemCount.ruleId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                  onTap: () async {
                                    if (await canLaunchUrl(
                                        Uri.parse(problemCount.ruleDocUri))) {
                                      await launchUrl(
                                          Uri.parse(problemCount.ruleDocUri));
                                    } else {
                                      throw 'Could not launch ${problemCount.ruleDocUri}';
                                    }
                                  },
                                ),
                                Text("${problemCount.count}")
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow unused(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            value,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
