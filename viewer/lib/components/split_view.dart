// Copyright 2021 Google LLC. All Rights Reserved.
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
import 'package:split_view/split_view.dart';

enum Side { top, bottom, right, left }

class CustomSplitView extends SplitView {
  CustomSplitView({
    required SplitViewMode viewMode,
    Widget? view1,
    Widget? view2,
    double initialWeight = 0.5,
  }) : super(
          viewMode: viewMode,
          children: [
            ThresholdBox(
                child: view1,
                side: (viewMode == SplitViewMode.Vertical)
                    ? Side.top
                    : Side.right),
            ThresholdBox(
                child: view2,
                side: (viewMode == SplitViewMode.Vertical)
                    ? Side.bottom
                    : Side.left)
          ],
          gripSize: 10,
        );
}

class ThresholdBox extends StatelessWidget {
  final Widget? child;
  final Side? side;
  final double width;
  final double height;
  ThresholdBox({this.child, this.side, this.width = 400, this.height = 100});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return ClipRect(
        child: OverflowBox(
          maxHeight: max(constraints.maxHeight, this.height),
          maxWidth: max(constraints.maxWidth, this.width),
          child: this.child,
          alignment: Alignment(
            (this.side == Side.left) ? 1 : -1,
            (this.side == Side.top) ? -1 : 1,
          ),
        ),
      );
    });
  }
}

double max(double a, double b) {
  return (a > b) ? a : b;
}
