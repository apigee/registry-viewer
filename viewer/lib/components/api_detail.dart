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
import '../components/api_edit.dart';
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
  ApiDetailCard({this.selflink, this.editable});
  _ApiDetailCardState createState() => _ApiDetailCardState();
}

class _ApiDetailCardState extends State<ApiDetailCard>
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
      return emptyCard(context, "api");
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
              child: AlertDialog(
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageSection(children: [
                      TitleRow(api.displayName, action: selflink),
                    ]),
                    PageSection(
                      children: [
                        BodyRow(
                          api.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          wrap: true,
                        ),
                      ],
                    ),
                    PageSection(
                      children: [
                        TimestampRow(api.createTime, api.updateTime),
                      ],
                    ),
                    if (api.labels.length > 0)
                      PageSection(children: [
                        LabelsRow(api.labels),
                      ]),
                    if (api.annotations.length > 0)
                      PageSection(children: [
                        AnnotationsRow(api.annotations),
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
