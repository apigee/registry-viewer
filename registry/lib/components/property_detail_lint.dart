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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_lint.pb.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/detail_rows.dart';
import '../helpers/extensions.dart';

String stringForLocation(LintLocation location) {
  return "${location.startPosition.lineNumber}:" +
      "${location.startPosition.columnNumber} - " +
      "${location.endPosition.lineNumber}:" +
      "${location.endPosition.columnNumber}";
}

class LintPropertyCard extends StatefulWidget {
  final Property property;
  final Function selflink;
  LintPropertyCard(this.property, {this.selflink});

  _LintPropertyCardState createState() => _LintPropertyCardState();
}

class FileProblem {
  final LintFile file;
  final LintProblem problem;
  FileProblem(this.file, this.problem);
}

class _LintPropertyCardState extends State<LintPropertyCard> {
  Lint lint;
  List<FileProblem> problems = [];
  final ScrollController controller = ScrollController();

  Widget build(BuildContext context) {
    if (lint == null) {
      lint = new Lint.fromBuffer(widget.property.messageValue.value);
      lint.files.forEach((file) {
        file.problems.forEach((problem) {
          problems.add(FileProblem(file, problem));
        });
      });
    }
    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
            name: widget.property.name.last(1),
            show: widget.selflink,
            edit: null,
          ),
          Expanded(
            child: Scrollbar(
              controller: controller,
              child: ListView.builder(
                controller: controller,
                itemCount: problems?.length,
                itemBuilder: (BuildContext context, int index) {
                  if (problems == null) {
                    return Container();
                  }
                  final problem = problems[index];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                problem.file.filePath,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText2
                                    .copyWith(color: Colors.blue),
                              ),
                              Text(stringForLocation(problem.problem.location)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "${problem.problem.message}",
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              GestureDetector(
                                child: Text(problem.problem.ruleId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(color: Colors.blue)),
                                onTap: () async {
                                  if (await canLaunch(
                                      problem.problem.ruleDocUri)) {
                                    await launch(problem.problem.ruleDocUri);
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
