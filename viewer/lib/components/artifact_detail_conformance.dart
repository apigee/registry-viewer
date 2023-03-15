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
import 'spec_file.dart';
import '../components/split_view.dart';
import 'package:split_view/split_view.dart';

String stringForLocation(LintLocation location) {
  return "[${location.startPosition.lineNumber}:${location.startPosition.columnNumber}-${location.endPosition.lineNumber}:${location.endPosition.columnNumber}]";
}

class ConformanceReportArtifactCard extends StatefulWidget {
  final Artifact artifact;
  final Function? selflink;
  const ConformanceReportArtifactCard(this.artifact,
      {this.selflink, super.key});

  @override
  ConformanceReportArtifactCardState createState() =>
      ConformanceReportArtifactCardState();
}

class FileProblem {
  final RuleReport report;
  FileProblem(this.report);
}

class ConformanceReportArtifactCardState
    extends State<ConformanceReportArtifactCard> {
  ConformanceReport? report;
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

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      report = ConformanceReport.fromBuffer(widget.artifact.contents);
      for (var guidelineReportGroup in report!.guidelineReportGroups) {
        for (var guidelineReport in guidelineReportGroup.guidelineReports) {
          for (var ruleReportGroup in guidelineReport.ruleReportGroups) {
            for (var ruleReport in ruleReportGroup.ruleReports) {
              problems.add(FileProblem(ruleReport));
            }
          }
        }
      }
      //}
    }
    return Card(
      child: CustomSplitView(
        viewMode: SplitViewMode.Vertical,
        view1: const SizedBox(height: 300, child: SpecFileCard()),
        view2: Column(
          children: [
            ResourceNameButtonRow(
              name: widget.artifact.name.last(1),
              show: widget.selflink as void Function()?,
              edit: null,
            ),
            Expanded(
              child: problems.isEmpty
                  ? const Center(child: Text("no problems found"))
                  : Scrollbar(
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
                                  .update(problem.report.file);
                              final location = problem.report.location;
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
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withAlpha(64)
                                    : Theme.of(context).canvasColor,
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${problem.report.file} ${stringForLocation(problem.report.location)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              fontWeight: FontWeight.bold),
                                      softWrap: false,
                                      overflow: TextOverflow.clip,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      problem.report.description,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    if (problem.report.suggestion != "")
                                      Text(
                                        problem.report.suggestion,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          child: Text(problem.report.ruleId,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor)),
                                          onTap: () async {
                                            if (await canLaunchUrl(Uri.parse(
                                                problem.report.docUri))) {
                                              await launchUrl(Uri.parse(
                                                  problem.report.docUri));
                                            } else {
                                              throw 'Could not launch ${problem.report.docUri}';
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
      ),
    );
  }

  TableRow row(BuildContext context, String label, String value) {
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
