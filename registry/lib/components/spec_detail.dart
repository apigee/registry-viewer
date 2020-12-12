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
import '../models/spec.dart';
import 'detail_rows.dart';
import '../service/registry.dart';
import '../components/spec_edit.dart';
import '../helpers/extensions.dart';

// SpecDetailCard is a card that displays details about a spec.
class SpecDetailCard extends StatefulWidget {
  final bool selflink;
  final bool editable;
  SpecDetailCard({this.selflink, this.editable});
  @override
  _SpecDetailCardState createState() => _SpecDetailCardState();
}

class _SpecDetailCardState extends State<SpecDetailCard> {
  SpecManager specManager;
  void listener() {
    setState(() {});
  }

  void setSpecName(String name) {
    if (specManager?.name == name) {
      return;
    }
    // forget the old manager
    specManager?.removeListener(listener);
    // get the new manager
    specManager = RegistryProvider.of(context).getSpecManager(name);
    specManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).specName.addListener(() {
      setState(() {
        setSpecName(SelectionProvider.of(context).specName.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Function selflink = onlyIf(widget.selflink, () {
      Spec spec = specManager?.value;
      Navigator.pushNamed(
        context,
        spec.routeNameForDetail(),
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
                content: EditSpecForm(),
              ),
            );
          });
    });

    if (specManager?.value == null) {
      return Card();
    } else {
      Spec spec = specManager.value;
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResourceNameButtonRow(
              name: spec.name.last(2),
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
                      TitleRow(spec.name.split("/").last, action: selflink),
                      SizedBox(height: 10),
                      BodyRow("revision " + spec.revisionId),
                      BodyRow(spec.style),
                      BodyRow("${spec.sizeBytes} bytes"),
                      if (spec.description != "") BodyRow(spec.description),
                      SizedBox(height: 10),
                      TimestampRow("created", spec.createTime),
                      TimestampRow("updated", spec.updateTime),
                      DetailRow(""),
                      DetailRow("$spec"),
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
