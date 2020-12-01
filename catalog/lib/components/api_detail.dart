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
import '../components/api_edit.dart';
import '../components/detail_rows.dart';
import '../models/selection.dart';
import '../models/api.dart';
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

  void listener() {
    setState(() {});
  }

  void setApiName(String name) {
    if (apiManager?.name == name) {
      return;
    }
    // forget the old manager
    apiManager?.removeListener(listener);
    // get the new manager
    apiManager = RegistryProvider.of(context).getApiManager(name);
    apiManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).apiName.addListener(() {
      setState(() {
        setApiName(SelectionProvider.of(context).apiName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    apiManager?.removeListener(listener);
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
                content: EditAPIForm(),
              ),
            );
          });
    });

    if (apiManager?.value == null) {
      return Card();
    } else {
      final api = apiManager.value;
      return Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResourceNameButtonRow(
                          name: api.name.split("/").sublist(2).join("/"),
                          show: selflink,
                          edit: editable),
                      SizedBox(height: 10),
                      TitleRow(api.displayName, action: selflink),
                      SizedBox(height: 10),
                      BodyRow(api.description),
                      SizedBox(height: 10),
                      TimestampRow("created", api.createTime),
                      TimestampRow("updated", api.updateTime),
                      DetailRow(""),
                      DetailRow("$api"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
