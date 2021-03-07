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
import '../models/api.dart';
import '../models/selection.dart';
import '../service/registry.dart';

// ApiDetailCard is a card that displays details about a api.
class ApiDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  ApiDetailCard({this.selflink, this.editable});
  _ApiDetailCardState createState() => _ApiDetailCardState();
}

class _ApiDetailCardState extends State<ApiDetailCard> {
  ApiManager apiManager;
  Selection selection;

  void managerListener() {
    setState(() {});
  }

  void selectionListener() {
    setState(() {
      setApiName(SelectionProvider.of(context).apiName.value);
    });
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(managerListener);
    // get the new manager
    apiManager = RegistryProvider.of(context).getApiManager(name);
    apiManager.addListener(managerListener);
    // get the value from the manager
    managerListener();
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection.apiName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    apiManager?.removeListener(managerListener);
    selection.apiName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Api api = apiManager?.value;
      Navigator.pushNamed(
        context,
        api.routeNameForDetail(),
      );
    });
    Function editable = onlyIf(widget.editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: DialogBuilder(
                  child: EditAPIForm(),
                ),
              ),
            );
          });
    });

    if (apiManager?.value == null) {
      return Card();
    } else {
      final api = apiManager.value;
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResourceNameButtonRow(
              name: api.name.split("/").sublist(2).join("/"),
              show: selflink,
              edit: editable,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      TitleRow(api.displayName, action: selflink),
                      SizedBox(height: 10),
                      BodyRow(api.description),
                      SizedBox(height: 10),
                      TimestampRow(api.createTime, api.updateTime),
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
}
