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

class Selection extends ChangeNotifier {
  ObservableString projectName = ObservableString();
  ObservableString apiName = ObservableString();
  ObservableString versionName = ObservableString();
  ObservableString specName = ObservableString();
  ObservableString labelName = ObservableString();
  ObservableString propertyName = ObservableString();

  void updateProjectName(String project) {
    this.projectName.update(project);
    this.apiName.update("");
    this.versionName.update("");
    this.specName.update("");
    this.labelName.update("");
    this.propertyName.update("");
  }

  void updateApiName(String api) {
    this.apiName.update(api);
    this.versionName.update("");
    this.specName.update("");
    this.labelName.update("");
    this.propertyName.update("");
  }

  void updateVersionName(String version) {
    this.versionName.update(version);
    this.specName.update("");
    this.labelName.update("");
    this.propertyName.update("");
  }

  void updateSpecName(String spec) {
    this.specName.update(spec);
    this.labelName.update("");
    this.propertyName.update("");
  }

  void updateLabelName(String label) {
    this.labelName.update(label);
  }

  void updatePropertyName(String property) {
    this.propertyName.update(property);
  }

  void notifySubscribersOf(String subject) {
    List<ObservableString> strings = [
      this.projectName,
      this.apiName,
      this.versionName,
      this.specName,
      this.propertyName,
      this.labelName,
    ];
    strings.forEach((v) {
      if (v.value == subject) {
        v.notifyListeners();
      }
    });
  }
}

class SelectionProvider extends InheritedWidget {
  final Selection selection;

  const SelectionProvider(
      {Key key, @required this.selection, @required Widget child})
      : assert(selection != null),
        assert(child != null),
        super(key: key, child: child);

  static Selection of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SelectionProvider>()
      ?.selection;

  @override
  bool updateShouldNotify(SelectionProvider oldWidget) =>
      selection != oldWidget.selection;

  static ObservableString project(BuildContext context) {
    return SelectionProvider.of(context).projectName;
  }

  static ObservableString api(BuildContext context) {
    return SelectionProvider.of(context).apiName;
  }

  static ObservableString version(BuildContext context) {
    return SelectionProvider.of(context).versionName;
  }

  static ObservableString spec(BuildContext context) {
    return SelectionProvider.of(context).specName;
  }

  static ObservableString label(BuildContext context) {
    return SelectionProvider.of(context).labelName;
  }

  static ObservableString property(BuildContext context) {
    return SelectionProvider.of(context).propertyName;
  }
}
