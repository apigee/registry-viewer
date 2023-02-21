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
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/api_edit.dart';
import '../components/artifact_card.dart';
import '../components/detail_rows.dart';
import '../components/dialog_builder.dart';
import '../components/empty.dart';
import '../models/api.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ApiDetailCard is a card that displays details about a api.
class ApiDetailCard extends StatefulWidget {
  final bool? selflink;
  final bool? editable;
  const ApiDetailCard({super.key, this.selflink, this.editable});
  @override
  ApiDetailCardState createState() => ApiDetailCardState();
}

class ApiDetailCardState extends State<ApiDetailCard>
    with AutomaticKeepAliveClientMixin {
  ApiManager? apiManager;
  Selection? selection;
  @override
  bool get wantKeepAlive => true;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setApiName(SelectionProvider.of(context)!.apiName.value);
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

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.apiName.addListener(selectionListener);
    super.didChangeDependencies();
    selectionListener();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    selection!.apiName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (apiManager?.value == null) {
      return emptyCard(context);
    }

    Function? selflink = onlyIf(widget.selflink, () {
      Api api = (apiManager?.value)!;
      Navigator.pushNamed(
        context,
        api.routeNameForDetail(),
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
                  child: EditAPIForm(),
                ),
              ),
            );
          });
    });
    final api = apiManager!.value!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceNameButtonRow(
            name: api.name.split("/").sublist(4).join("/"),
            show: selflink as void Function()?,
            edit: editable as void Function()?,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageSection(children: [
                      TitleRow(api.displayName, action: selflink),
                    ]),
                    if (api.labels.isNotEmpty)
                      PageSection(children: [
                        LabelsRow(api.labels),
                      ]),
                    if (api.annotations.isNotEmpty)
                      PageSection(children: [
                        AnnotationsRow(api.annotations),
                      ]),
                    PageSection(
                      children: [
                        TimestampRow(api.createTime, api.updateTime),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          child: const Text("Versions"),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              api.routeNameForVersions(),
                            );
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Deployments"),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              api.routeNameForDeployments(),
                            );
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Artifacts"),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              api.routeNameForArtifacts(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Theme.of(context).primaryColor,
                    ),
                    ArtifactCard(
                      () =>
                          "${SelectionProvider.of(context)!.apiName.value}/artifacts/summary",
                    ),
                    ArtifactCard(
                      () =>
                          "${SelectionProvider.of(context)!.apiName.value}/artifacts/related",
                    ),
                    MarkdownBody(
                      data: api.description,
                      onTapLink: (text, url, title) {
                        launchUrl(Uri.parse(url!));
                      },
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
