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
import '../models/api.dart';
import '../models/version.dart';
import '../helpers/title.dart';
import '../components/api_edit.dart';

class ApiDetailPage extends StatefulWidget {
  final String name;
  final Api api;

  ApiDetailPage({this.name, this.api});
  @override
  _ApiDetailPageState createState() => _ApiDetailPageState(this.api);
}

class _ApiDetailPageState extends State<ApiDetailPage> {
  Api api;
  List<Property> properties;

  _ApiDetailPageState(this.api);

  @override
  Widget build(BuildContext context) {
    final apiName = widget.name.substring(1);
    if (api == null) {
      // we need to fetch the api from the API
      final apiFuture = ApiService().getApi(apiName);
      apiFuture.then((api) {
        setState(() {
          this.api = api;
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
              Row(children: [apiCard(context, api)]),
              Row(children: [
                ApiVersionListWidget(api, "captain"),
                apiInfoCard(context, api),
              ]),
              Row(children: [
                apiInfoCard(context, api),
                apiInfoCard(context, api),
                apiInfoCard(context, api)
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Expanded apiCard(BuildContext context, Api api) {
  return Expanded(
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(api.displayName,
                style: Theme.of(context).textTheme.headline5),
            subtitle: Text(api.description + "\n" + api.owner),
          ),
          ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text('EDIT'),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: EditAPIForm(api),
                        );
                      });
                },
              ),
              FlatButton(
                child: const Text('VERSIONS'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    api.routeNameForVersions(),
                    arguments: api,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Expanded apiInfoCard(BuildContext context, Api api) {
  return Expanded(
    child: Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title:
                Text("More Info", style: Theme.of(context).textTheme.headline6),
            subtitle: Text("$api"),
          ),
          ButtonBar(
            children: <Widget>[
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

class ApiVersionListWidget extends StatefulWidget {
  final Api api;
  final String name;

  ApiVersionListWidget(this.api, this.name);
  @override
  _ApiVersionListWidgetState createState() =>
      _ApiVersionListWidgetState(this.api);
}

class _ApiVersionListWidgetState extends State<ApiVersionListWidget> {
  final Api api;
  List<Version> versions;

  _ApiVersionListWidgetState(this.api);

  @override
  Widget build(BuildContext context) {
    if (versions == null) {
      // we need to fetch the versions from the API
      final versionsFuture = VersionService().getVersions(api.name);
      versionsFuture.then((versions) {
        setState(() {
          this.versions = versions;
        });
      });
      return Expanded(
        child: Card(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
            ),
            child: ListTile(
              title: Text("Loading...",
                  style: Theme.of(context).textTheme.headline6),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: <Widget>[
                  Text("Versions"),
                ] +
                versions.map((version) {
                  var name = version.name.split("/").last;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pushNamed(
                        context,
                        version.routeNameForDetail(),
                        arguments: version,
                      );
                    },
                    child: ListTile(
                      title: Text(name),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
