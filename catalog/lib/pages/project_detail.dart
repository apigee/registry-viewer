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
import '../models/project.dart';
import '../helpers/title.dart';
import '../service/registry.dart';

class ProjectDetailPage extends StatefulWidget {
  final String name;
  ProjectDetailPage({this.name});
  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  ProjectManager projectManager;
  List<Property> properties;

  void listener() {
    setState(() {});
  }

  _ProjectDetailPageState();

  @override
  void didChangeDependencies() {
    projectManager?.removeListener(listener);
    projectManager = RegistryProvider.of(context)
        .getProjectManager(widget.name.substring(1));
    projectManager.addListener(listener);
    listener();
    super.didChangeDependencies();
  }

  String subtitlePropertyText() {
    if (projectManager.value.description != null) {
      return projectManager.value.description;
    }
    if (properties == null) {
      return "";
    }
    for (var property in properties) {
      if (property.relation == "subtitle") {
        return property.stringValue;
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final projectName = widget.name.substring(1);
    if (projectManager?.value == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title(widget.name)),
        ),
        body: Text("loading..."),
      );
    }

    if (properties == null) {
      // fetch the properties
      final propertiesFuture =
          PropertiesService.listProperties(projectName, subject: projectName);
      propertiesFuture.then((properties) {
        setState(() {
          this.properties = properties.properties;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title(widget.name)),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
                //color:Colors.yellow,
                ),
            margin: EdgeInsets.fromLTRB(40, 20, 40, 0),
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              children: [
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: Text(projectManager.value.nameForDisplay(),
                            style: Theme.of(context).textTheme.headline2),
                        subtitle: Text(subtitlePropertyText()),
                      ),
                      ButtonBar(
                        children: <Widget>[
                          FlatButton(
                            child: const Text('APIs',
                                semanticsLabel: "APIs BUTTON"),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                projectManager.value.routeNameForApis(),
                                arguments: projectManager.value,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
