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
import 'package:google_fonts/google_fonts.dart';
import '../components/artifact_text.dart';
import '../components/detail_rows.dart';
import '../components/dialog_builder.dart';
import '../components/spec_edit.dart';
import '../components/empty.dart';
import '../helpers/extensions.dart';
import '../models/selection.dart';
import '../models/spec.dart';
import '../service/registry.dart';

// SpecDetailCard is a card that displays details about a spec.
class SpecDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  SpecDetailCard({this.selflink, this.editable});
  @override
  _SpecDetailCardState createState() => _SpecDetailCardState();
}

class _SpecDetailCardState extends State<SpecDetailCard>
    with AutomaticKeepAliveClientMixin {
  ApiManager? apiManager;
  VersionManager? versionManager;
  SpecManager? specManager;
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
      setSpecName(SelectionProvider.of(context)!.specName.value);
    });
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(managerListener);
    // get the new manager
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
    // get the new manager
    versionManager = RegistryProvider.of(context)!.getVersionManager(name);
    versionManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  void setSpecName(String name) {
    if (specManager?.name == name) {
      return;
    }
    // forget the old manager
    specManager?.removeListener(managerListener);
    // get the new manager
    specManager = RegistryProvider.of(context)!.getSpecManager(name);
    specManager!.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.specName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    versionManager?.removeListener(managerListener);
    specManager?.removeListener(managerListener);
    selection!.specName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (specManager?.value == null) {
      return emptyCard(context);
    }

    Function? selflink = onlyIf(widget.selflink, () {
      ApiSpec spec = (specManager?.value)!;
      Navigator.pushNamed(
        context,
        spec.routeNameForDetail(),
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
                  child: EditSpecForm(),
                ),
              ),
            );
          });
    });

    Api? api = apiManager!.value;
    ApiVersion? version = versionManager!.value;
    ApiSpec? spec = specManager!.value;
    if ((api == null) || (version == null) || (spec == null)) {
      return Card();
    }
    final codeStyle = GoogleFonts.inconsolata();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: spec.name.last(1),
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
                        SuperTitleRow(api.displayName +
                            "/" +
                            version.name.split("/").last),
                        TitleRow(spec.name.split("/").last, action: selflink),
                      ],
                    ),
                    if (spec.labels.length > 0)
                      PageSection(children: [
                        LabelsRow(spec.labels),
                      ]),
                    if (spec.annotations.length > 0)
                      PageSection(children: [
                        AnnotationsRow(spec.annotations),
                      ]),
                    if (spec.hasSourceUri())
                      PageSection(
                        children: [
                          LinkRow("${spec.sourceUri}", spec.sourceUri),
                        ],
                      ),
                    PageSection(
                      children: [
                        BodyRow(spec.mimeType, style: codeStyle),
                        BodyRow("revision " + spec.revisionId,
                            style: codeStyle),
                        BodyRow("${spec.sizeBytes} bytes", style: codeStyle),
                        BodyRow("SHA-256 ${spec.hash}", style: codeStyle),
                        TimestampRow(spec.createTime, spec.revisionUpdateTime),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          child: Text("Artifacts"),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              spec.routeNameForArtifacts(),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 10),
                    ArtifactText(
                      () =>
                          SelectionProvider.of(context)!.specName.value +
                          "/artifacts/summary",
                    ),
                    if (spec.description != "")
                      PageSection(
                        children: [
                          BodyRow(spec.description),
                        ],
                      ),
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
