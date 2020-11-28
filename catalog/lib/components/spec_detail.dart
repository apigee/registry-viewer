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
import '../models/spec.dart';
import 'info.dart';
import '../service/registry.dart';

// SpecDetailCard is a card that displays details about a spec.
class SpecDetailCard extends StatefulWidget {
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
    specManager = null;
    // get the new manager
    specManager = RegistryProvider.of(context).getSpecManager(name);
    specManager.addListener(listener);
    // get the value from the manager
    listener();
  }

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).spec.addListener(() {
      setState(() {
        setSpecName(SelectionProvider.of(context).spec.value);
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (specManager?.value == null) {
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
                  child: SpecInfoWidget(specManager.value),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class SpecInfoWidget extends StatelessWidget {
  final Spec spec;
  SpecInfoWidget(this.spec);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResourceNameButtonRow(
          name: spec.name.split("/").sublist(6).join("/"),
          show: () {
            Navigator.pushNamed(
              context,
              spec.routeNameForDetail(),
              arguments: spec,
            );
          },
        ),
        SizedBox(height: 10),
        TitleRow(spec.name.split("/").last),
        SizedBox(height: 10),
        BodyRow("revision " + spec.revisionId),
        BodyRow(spec.style),
        BodyRow("${spec.sizeBytes} bytes"),
        if (spec.description != "") BodyRow(spec.description),
        SizedBox(height: 10),
        TimestampRow("created", spec.createTime),
        TimestampRow("updated", spec.updateTime),
      ],
    );
  }
}
