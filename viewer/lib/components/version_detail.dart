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
import '../components/artifact_text.dart';
import '../components/detail_rows.dart';
import '../components/dialog_builder.dart';
import '../components/empty.dart';
import '../components/version_edit.dart';
import '../models/selection.dart';
import '../models/version.dart';
import '../service/registry.dart';

// VersionDetailCard is a card that displays details about a version.
class VersionDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  const VersionDetailCard({this.selflink, this.editable, super.key});
  @override
  VersionDetailCardState createState() => VersionDetailCardState();
}

class VersionDetailCardState extends State<VersionDetailCard>
    with AutomaticKeepAliveClientMixin {
  ApiManager? apiManager;
  VersionManager? versionManager;
  Selection? selection;
  @override
  bool get wantKeepAlive => true;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setApiName(SelectionProvider.of(context)!.apiName.value);
      setVersionName(SelectionProvider.of(context)!.versionName.value);
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

  void setVersionName(String name) {
    if (versionManager?.name == name) {
      return;
    }
    // forget the old manager
    versionManager?.removeListener(managerListener);
    // get a manager for the new name
    versionManager = RegistryProvider.of(context)!.getVersionManager(name);
    versionManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.versionName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    versionManager?.removeListener(managerListener);
    selection!.versionName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (versionManager?.value == null) {
      return emptyCard(context);
    }
    Function? selflink = onlyIf(widget.selflink, () {
      ApiVersion version = (versionManager?.value)!;
      Navigator.pushNamed(
        context,
        version.routeNameForDetail(),
      );
    });
    Function? editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: const AlertDialog(
                content: DialogBuilder(
                  child: EditVersionForm(),
                ),
              ),
            );
          });
    });

    Api? api = apiManager!.value;
    ApiVersion version = versionManager!.value!;
    var versionTitle = version.nameForDisplay();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageSection(
                      children: [
                        Text(version.name.split("/").sublist(6).join("/")),
                        SuperTitleRow(api?.displayName ?? ""),
                        TitleRow(versionTitle, action: selflink),
                      ],
                    ),
                    if (version.labels.isNotEmpty)
                      PageSection(children: [
                        LabelsRow(version.labels),
                      ]),
                    if (version.annotations.isNotEmpty)
                      PageSection(children: [
                        AnnotationsRow(version.annotations),
                      ]),
                    const SizedBox(height: 10),
                    ArtifactText(
                      () =>
                          "${SelectionProvider.of(context)!.versionName.value}/artifacts/summary",
                    ),
                    if (version.description != "")
                      PageSection(
                        children: [
                          BodyRow(version.description),
                        ],
                      )
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
