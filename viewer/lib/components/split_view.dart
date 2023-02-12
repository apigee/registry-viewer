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

class CustomSplitView extends StatefulWidget {
  final Widget? view1;
  final Widget? view2;
  final SplitViewMode? viewMode;
  final double initialWeight;

  const CustomSplitView({
    this.viewMode,
    this.view1,
    this.view2,
    this.initialWeight = 0.5,
  });

  @override
  CustomSplitViewState createState() => CustomSplitViewState();
}

class CustomSplitViewState extends State<CustomSplitView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SplitView(
      viewMode: widget.viewMode!,
      gripSize: 10,
      children: [
        ThresholdBox(
          side: (widget.viewMode == SplitViewMode.Vertical)
              ? Side.top
              : Side.right,
          child: widget.view1,
        ),
        ThresholdBox(
          side: (widget.viewMode == SplitViewMode.Vertical)
              ? Side.bottom
              : Side.left,
          child: widget.view2,
        )
      ],
    );
  }
}

class ThresholdBox extends StatelessWidget {
  final Widget? child;
  final Side? side;
  final double width;
  final double height;
  const ThresholdBox(
      {this.child, this.side, this.width = 400, this.height = 100});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return ClipRect(
        child: OverflowBox(
          maxHeight: max(constraints.maxHeight, height),
          maxWidth: max(constraints.maxWidth, width),
          child: child,
        ),
      );
    });
  }
}

double max(double a, double b) {
  return (a > b) ? a : b;
}
