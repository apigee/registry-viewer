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
import '../models/selection.dart';
import '../models/version.dart';
import 'detail_rows.dart';
import '../service/registry.dart';
import '../components/version_edit.dart';

// VersionDetailCard is a card that displays details about a version.
class VersionDetailCard extends StatefulWidget {
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
    if (versionManager?.value == null) {
      return Card();
    } else {
      return Card(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: VersionInfoWidget(versionManager.value),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class VersionInfoWidget extends StatelessWidget {
  final Version version;
  VersionInfoWidget(this.version);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResourceNameButtonRow(
          name: version.name.split("/").sublist(4).join("/"),
          show: () {
            Navigator.pushNamed(
              context,
              version.routeNameForDetail(),
              arguments: version,
            );
          },
          edit: () {
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
          },
        ),
        SizedBox(height: 10),
        TitleRow(version.name.split("/").last),
        SizedBox(height: 10),
        if (version.description != "") BodyRow(version.description),
        SizedBox(height: 10),
        TimestampRow("created", version.createTime),
        TimestampRow("updated", version.updateTime),
      ],
    );
  }
}
