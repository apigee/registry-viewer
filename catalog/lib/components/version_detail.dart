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
import '../models/selection.dart';
import '../models/version.dart';

// VersionDetailCard is a card that displays details about a version.
class VersionDetailCard extends StatefulWidget {
  _VersionDetailCardState createState() => _VersionDetailCardState();
}

class _VersionDetailCardState extends State<VersionDetailCard> {
  String versionName = "";
  Version version;

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).version.addListener(() => setState(() {
          versionName = SelectionProvider.of(context).version.value;
          if (versionName == null) {
            versionName = "";
          }
          this.version = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (version == null) {
      if (versionName != "") {
        // we need to fetch the version from the API
        VersionService().getVersion(versionName).then((version) {
          setState(() {
            this.version = version;
          });
        });
      }
      return Card();
    } else {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text("$version"),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextButton(
                  child: Text("Version Details"),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      version.routeNameForDetail(),
                      arguments: version,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
