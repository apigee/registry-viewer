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
import '../service/service.dart';
import '../helpers/title.dart';
import '../components/logout.dart';
import '../components/spec_list.dart';

// convert /projects/{project}/apis/{api}/versions/{version}/specs
// to projects/{project}/apis/{api}/versions/{version}
String parent(String name) {
  var parts = name.split('/');
  return parts.sublist(1, 7).join('/');
}

// SpecListPage is a full-page display of a list of specs.
class SpecListPage extends StatelessWidget {
  final String name;
  final String versionName;
  SpecListPage(String name, {Key key})
      : name = name,
        versionName = parent(name),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var specList = SpecList(SpecService(versionName));
    return Scaffold(
      appBar: AppBar(
        title: Text(title(name)),
        actions: <Widget>[
          SpecSearchBox(specList),
          logoutButton(context),
        ],
      ),
      body: Center(child: specList),
    );
  }
}
