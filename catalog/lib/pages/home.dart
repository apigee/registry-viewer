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
import '../application.dart';
import 'project_list.dart';
import 'api_list.dart';
import 'version_list.dart';
import 'spec_list.dart';

class ObservableString extends ChangeNotifier {
  String value;
  void update(String value) {
    if (this.value != value) {
      this.value = value;
      notifyListeners();
    }
  }
}

class SelectionModel extends ChangeNotifier {
  ObservableString project = ObservableString();
  ObservableString api = ObservableString();
  ObservableString version = ObservableString();
  ObservableString spec = ObservableString();

  void updateProject(String project) {
    this.project.update(project);
    this.api.update("");
    this.version.update("");
    this.spec.update("");
  }

  void updateApi(String api) {
    this.api.update(api);
    this.version.update("");
    this.spec.update("");
  }

  void updateVersion(String version) {
    this.version.update(version);
    this.spec.update("");
    ;
  }

  void updateSpec(String spec) {
    this.spec.update(spec);
  }
}

class ModelProvider extends InheritedWidget {
  final SelectionModel model;

  const ModelProvider({Key key, @required this.model, @required Widget child})
      : assert(model != null),
        assert(child != null),
        super(key: key, child: child);

  static SelectionModel of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ModelProvider>()?.model;

  @override
  bool updateShouldNotify(ModelProvider oldWidget) => model != oldWidget.model;
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SelectionModel model = SelectionModel();

    final projectListCard = ProjectListCard();
    final apiListCard = ApiListCard();
    final versionListCard = VersionListCard();
    final specListCard = SpecListCard();
    return ModelProvider(
      model: model,
      child: Scaffold(
        appBar: AppBar(
          title: Text(applicationName),
        ),
        body: Row(
          children: [
            Expanded(
              child: projectListCard,
            ),
            Expanded(
              child: apiListCard,
            ),
            Expanded(
              child: versionListCard,
            ),
            Expanded(
              child: specListCard,
            ),
          ],
        ),
      ),
    );
  }
}
