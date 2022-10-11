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

class Highlight {
  int startRow;
  int startCol;
  int endRow;
  int endCol;
  Highlight(this.startRow, this.startCol, this.endRow, this.endCol);

  String toString() {
    return "Highlight($startRow:$startCol-$endRow:$endCol)";
  }
}

class ObservableHighlight extends ValueNotifier<Highlight?> {
  ObservableHighlight() : super(Highlight(0, 0, 0, 0));
  void update(Highlight? value) {
    this.value = value;
    notifyListeners();
  }
}

class ObservableHighlightProvider extends InheritedWidget {
  final ObservableHighlight observable;

  const ObservableHighlightProvider(
      {Key? key, required this.observable, required Widget child})
      : super(key: key, child: child);

  static ObservableHighlight? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ObservableHighlightProvider>()
      ?.observable;

  @override
  bool updateShouldNotify(ObservableHighlightProvider oldWidget) =>
      observable != oldWidget.observable;
}
