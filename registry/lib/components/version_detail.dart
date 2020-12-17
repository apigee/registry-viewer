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
import '../models/selection.dart';
import '../models/version.dart';
import 'detail_rows.dart';
import '../service/registry.dart';
import '../components/version_edit.dart';

// VersionDetailCard is a card that displays details about a version.
class VersionDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  VersionDetailCard({this.selflink, this.editable});
  _VersionDetailCardState createState() => _VersionDetailCardState();
}

class _VersionDetailCardState extends State<VersionDetailCard> {
  VersionManager versionManager;

  void listener() {
    setState(() {});
  }

  void setVersionName(String name) {
    if (versionManager?.name == name) {
      return;
    }
    // forget the old manager
    versionManager?.removeListener(listener);
    // get a manager for the new name
    versionManager = RegistryProvider.of(context).getVersionManager(name);
    versionManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).versionName.addListener(() {
      setState(() {
        setVersionName(SelectionProvider.of(context).versionName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Version version = versionManager?.value;
      Navigator.pushNamed(
        context,
        version.routeNameForDetail(),
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
                content: EditVersionForm(),
              ),
            );
          });
    });

    if (versionManager?.value == null) {
      return Card();
    } else {
      Version version = versionManager.value;
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResourceNameButtonRow(
              name: version.name.split("/").sublist(4).join("/"),
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
                      TitleRow(version.name.split("/").last, action: selflink),
                      SizedBox(height: 10),
                      if (version.description != "")
                        BodyRow(version.description),
                      SizedBox(height: 10),
                      TimestampRow(version.createTime, version.updateTime),
                      DetailRow("$version"),
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
