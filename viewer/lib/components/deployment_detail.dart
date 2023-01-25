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
import '../components/dialog_builder.dart';
import '../components/deployment_edit.dart';
import '../components/empty.dart';
import '../models/selection.dart';
import '../models/deployment.dart';
import '../service/registry.dart';

// DeploymentDetailCard is a card that displays details about a deployment.
class DeploymentDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  DeploymentDetailCard({this.selflink, this.editable});
  _DeploymentDetailCardState createState() => _DeploymentDetailCardState();
}

class _DeploymentDetailCardState extends State<DeploymentDetailCard> {
  ApiManager? apiManager;
  DeploymentManager? deploymentManager;
  Selection? selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setApiName(SelectionProvider.of(context)!.apiName.value);
      setDeploymentName(SelectionProvider.of(context)!.deploymentName.value);
    });
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(managerListener);
    // get a manager for the new name
    apiManager = RegistryProvider.of(context)!.getApiManager(name);
    apiManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  void setDeploymentName(String name) {
    if (deploymentManager?.name == name) {
      return;
    }
    // forget the old manager
    deploymentManager?.removeListener(managerListener);
    // get a manager for the new name
    deploymentManager =
        RegistryProvider.of(context)!.getDeploymentManager(name);
    deploymentManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.deploymentName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    deploymentManager?.removeListener(managerListener);
    selection!.deploymentName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (deploymentManager?.value == null) {
      return emptyCard(context, "deployment");
    }
    Function? selflink = onlyIf(widget.selflink, () {
      ApiDeployment deployment = (deploymentManager?.value)!;
      Navigator.pushNamed(
        context,
        deployment.routeNameForDetail(),
      );
    });
    Function? editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: AlertDialog(
                content: DialogBuilder(
                  child: EditDeploymentForm(),
                ),
              ),
            );
          });
    });

    Api? api = apiManager!.value;
    ApiDeployment deployment = deploymentManager!.value!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: deployment.name.split("/").sublist(4).join("/"),
            show: selflink as void Function()?,
            edit: editable as void Function()?,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageSection(
                      children: [
                        SizedBox(height: 10),
                        SuperTitleRow(api?.displayName ?? ""),
                        TitleRow(deployment.name.split("/").last,
                            action: selflink),
                      ],
                    ),
                    if (deployment.description != "")
                      PageSection(
                        children: [
                          BodyRow(deployment.description),
                        ],
                      ),
                    PageSection(
                      children: [
                        TimestampRow(deployment.createTime,
                            deployment.revisionUpdateTime),
                      ],
                    ),
                    if (deployment.labels.length > 0)
                      PageSection(children: [
                        LabelsRow(deployment.labels),
                      ]),
                    if (deployment.annotations.length > 0)
                      PageSection(children: [
                        AnnotationsRow(deployment.annotations),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
