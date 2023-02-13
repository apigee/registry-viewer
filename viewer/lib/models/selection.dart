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
import 'string.dart';
import 'highlight.dart';

class Selection extends ChangeNotifier {
  ObservableString projectName = ObservableString();
  ObservableString apiName = ObservableString();
  ObservableString versionName = ObservableString();
  ObservableString specName = ObservableString();
  ObservableString deploymentName = ObservableString();
  ObservableString labelName = ObservableString();
  ObservableString artifactName = ObservableString();
  ObservableString fileName = ObservableString();
  ObservableHighlight highlight = ObservableHighlight();

  void updateProjectName(String project) {
    projectName.update(project);
    apiName.update("");
    versionName.update("");
    specName.update("");
    deploymentName.update("");
    labelName.update("");
    artifactName.update("");
    fileName.update("");
    highlight.update(null);
  }

  void updateApiName(String api) {
    apiName.update(api);
    versionName.update("");
    specName.update("");
    deploymentName.update("");
    labelName.update("");
    artifactName.update("");
    fileName.update("");
    highlight.update(null);
  }

  void updateVersionName(String version) {
    versionName.update(version);
    specName.update("");
    labelName.update("");
    artifactName.update("");
    fileName.update("");
    highlight.update(null);
  }

  void updateDeploymentName(String deployment) {
    deploymentName.update(deployment);
    labelName.update("");
    artifactName.update("");
  }

  void updateSpecName(String spec) {
    specName.update(spec);
    labelName.update("");
    artifactName.update("");
    fileName.update("");
    highlight.update(null);
  }

  void updateLabelName(String label) {
    labelName.update(label);
  }

  void updateArtifactName(String artifact) {
    artifactName.update(artifact);
  }

  void updateFilename(String file) {
    fileName.update(file);
  }

  void updateHighight(Highlight h) {
    highlight.update(h);
  }

  void notifySubscribersOf(String subject) {
    List<ObservableString> strings = [
      projectName,
      apiName,
      versionName,
      specName,
      deploymentName,
      artifactName,
      labelName,
      fileName,
    ];
    for (var v in strings) {
      if (v.value == subject) {
        v.notifyListeners();
      }
    }
  }
}

class SelectionProvider extends InheritedWidget {
  final Selection selection;

  const SelectionProvider(
      {Key? key, required this.selection, required Widget child})
      : super(key: key, child: child);

  static Selection? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SelectionProvider>()
      ?.selection;

  @override
  bool updateShouldNotify(SelectionProvider oldWidget) =>
      selection != oldWidget.selection;

  static ObservableString project(BuildContext context) {
    return SelectionProvider.of(context)!.projectName;
  }

  static ObservableString api(BuildContext context) {
    return SelectionProvider.of(context)!.apiName;
  }

  static ObservableString version(BuildContext context) {
    return SelectionProvider.of(context)!.versionName;
  }

  static ObservableString deployment(BuildContext context) {
    return SelectionProvider.of(context)!.deploymentName;
  }

  static ObservableString spec(BuildContext context) {
    return SelectionProvider.of(context)!.specName;
  }

  static ObservableString label(BuildContext context) {
    return SelectionProvider.of(context)!.labelName;
  }

  static ObservableString artifact(BuildContext context) {
    return SelectionProvider.of(context)!.artifactName;
  }

  static ObservableString file(BuildContext context) {
    return SelectionProvider.of(context)!.fileName;
  }

  static ObservableHighlight highlight(BuildContext context) {
    return SelectionProvider.of(context)!.highlight;
  }
}
