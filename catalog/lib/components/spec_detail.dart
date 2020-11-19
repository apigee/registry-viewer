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

// SpecDetailCard is a card that displays details about a spec.
class SpecDetailCard extends StatefulWidget {
  _SpecDetailCardState createState() => _SpecDetailCardState();
}

class _SpecDetailCardState extends State<SpecDetailCard> {
  String specName = "";
  Spec spec;

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).spec.addListener(() => setState(() {
          specName = SelectionProvider.of(context).spec.value;
          if (specName == null) {
            specName = "";
          }
          this.spec = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (spec == null) {
      if (specName != "") {
        // we need to fetch the spec from the API
        SpecService().getSpec(specName).then((spec) {
          setState(() {
            spec.contents = List<int>();
            this.spec = spec;
          });
        });
      }
      return Card();
    } else {
      return Card(
        child: SingleChildScrollView(
          child: Text("$spec"),
        ),
      );
    }
  }
}
