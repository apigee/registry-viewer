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
import '../models/selection.dart';
import '../models/highlight.dart';

String stringForLocation(LintLocation location) {
  return "[${location.startPosition.lineNumber}:" +
      "${location.startPosition.columnNumber}-" +
      "${location.endPosition.lineNumber}:" +
      "${location.endPosition.columnNumber}]";
}

class LintArtifactCard extends StatefulWidget {
  final Artifact artifact;
  final Function? selflink;
  const LintArtifactCard(this.artifact, {this.selflink});

  _LintArtifactCardState createState() => _LintArtifactCardState();
}

class FileProblem {
  final LintFile file;
  final LintProblem problem;
  FileProblem(this.file, this.problem);
}

class _LintArtifactCardState extends State<LintArtifactCard> {
  Lint? lint;
  List<FileProblem> problems = [];
  final ScrollController controller = ScrollController();
  int selectedIndex = -1;
  Selection? selection;

  void highlightListener() {
    Highlight? highlight = SelectionProvider.of(context)!.highlight.value;
    if (highlight == null) {
      setState(() {
        selectedIndex = -1;
      });
    }
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.highlight.addListener(highlightListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    selection!.highlight.removeListener(highlightListener);
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (lint == null) {
      lint = Lint.fromBuffer(widget.artifact.contents);
      lint!.files.forEach((file) {
        file.problems.forEach((problem) {
          problems.add(FileProblem(file, problem));
        });
      });
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
                itemCount: problems.length,
                itemBuilder: (BuildContext context, int index) {
                  final problem = problems[index];
                  return GestureDetector(
                    onTap: () {
                      selectedIndex = index;
                      SelectionProvider.of(context)!
                          .fileName
                          .update(problem.file.filePath);
                      final location = problem.problem.location;
                      Highlight highlight = Highlight(
                        location.startPosition.lineNumber - 1,
                        location.startPosition.columnNumber - 1,
                        location.endPosition.lineNumber - 1,
                        location.endPosition.columnNumber - 1,
                      );
                      SelectionProvider.of(context)!
                          .highlight
                          .update(highlight);
                      setState(() {});
                    },
                    child: Card(
                      child: Container(
                        color: (selectedIndex == index)
                            ? Theme.of(context).primaryColor.withAlpha(64)
                            : Theme.of(context).canvasColor,
                        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.file.filePath +
                                  " " +
                                  stringForLocation(problem.problem.location),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                              softWrap: false,
                              overflow: TextOverflow.clip,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "${problem.problem.message}",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (problem.problem.suggestion != "")
                              Text(
                                "${problem.problem.suggestion}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  child: Text(problem.problem.ruleId,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor)),
                                  onTap: () async {
                                    if (await canLaunchUrl(Uri.parse(
                                        problem.problem.ruleDocUri))) {
                                      await launchUrl(Uri.parse(
                                          problem.problem.ruleDocUri));
                                    } else {
                                      throw 'Could not launch ${problem.problem.ruleDocUri}';
                                    }
                                  },
                                ),
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

  TableRow row(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(
            value,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
