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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/observable.dart';

// LabelsCard
typedef ObservableStringProvider = ObservableString Function(
    BuildContext context);

class LabelsCard extends StatefulWidget {
  final ObservableStringProvider getObservableResourceName;
  LabelsCard(this.getObservableResourceName);

  @override
  _LabelsCardState createState() => _LabelsCardState();
}

class _LabelsCardState extends State<LabelsCard> {
  ObservableString subjectNameManager;
  String subjectName;
  List<Label> labels;

  String projectName() {
    return subjectName.split("/").sublist(0, 2).join("/");
  }

  void listener() {
    setState(() {
      subjectName = subjectNameManager.value;
      if (subjectName == null) {
        subjectName = "";
      }
      this.labels = null;
    });
  }

  @override
  void didChangeDependencies() {
    subjectNameManager = widget.getObservableResourceName(context);
    subjectNameManager.addListener(listener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    subjectNameManager?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (subjectName == null) {
      return Card(child: Center(child: Text("no subject")));
    }
    if (labels == null) {
      // we need to fetch the labels from the API
      LabelsService.listLabels(projectName(), subject: subjectName)
          .then((labels) {
        print("got $labels");
        setState(() {
          this.labels = labels.labels;
        });
      });
      return Card(child: Center(child: Text("loading")));
    }
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Labels",
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Table(
              columnWidths: {
                0: IntrinsicColumnWidth(),
              },
              children: labels.map(
                (label) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Text(
                          label.name.split("/").last,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  );
                },
              ).toList()),
        ],
      ),
    );
  }
}
