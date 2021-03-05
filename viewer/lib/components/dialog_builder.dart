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

class DialogBuilder extends StatelessWidget {
  final Widget child;
  DialogBuilder({this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      // Get available height and width of the build area of this widget. Make a choice depending on the size.
      var height = MediaQuery.of(context).size.height;
      var width = MediaQuery.of(context).size.width;

      return Container(
        height: height - 400,
        width: width - 200,
        child: child,
      );
    });
  }
}
