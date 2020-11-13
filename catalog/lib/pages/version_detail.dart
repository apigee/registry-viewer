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
import '../application.dart';
import '../models/version.dart';
import '../helpers/title.dart';

class VersionDetailPage extends StatefulWidget {
  final String name;
  final Version version;
  VersionDetailPage({this.name, this.version});
  @override
  _VersionDetailPageState createState() =>
      _VersionDetailPageState(this.version);
}

class _VersionDetailPageState extends State<VersionDetailPage> {
  Version version;
  List<Property> properties;

  _VersionDetailPageState(this.version);

  @override
  Widget build(BuildContext context) {
    final versionName = widget.version.name;
    if (version == null) {
      // we need to fetch the version from the API
      final versionFuture = VersionService.getVersion(versionName);
      versionFuture.then((version) {
        setState(() {
          this.version = version;
        });
      });
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title(widget.name),
          ),
        ),
        body: Text("loading..."),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title(widget.name),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Row(children: [versionCard(context, version)]),
            ],
          ),
        ),
      ),
    );
  }
}

Expanded versionCard(BuildContext context, Version version) {
  return Expanded(
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(version.name,
                style: Theme.of(context).textTheme.headline5),
            subtitle: Text("$version"),
          ),
          ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text('SPECS'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    version.routeNameForSpecs(),
                    arguments: version,
                  );
                },
              ),
              FlatButton(
                child: const Text('MORE'),
                onPressed: () {/* ... */},
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
