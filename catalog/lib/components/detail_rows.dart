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
import '../helpers/timestamp.dart';
import 'package:catalog/generated/google/protobuf/timestamp.pb.dart';

class ResourceNameButtonRow extends StatelessWidget {
  final String name;
  final void Function() show;
  final void Function() edit;
  ResourceNameButtonRow({this.name, this.show, this.edit});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        TextButton(
          child: Text("EDIT"),
          onPressed: edit != null ? edit : () {},
        ),
        TextButton(
          child: Text(name),
          onPressed: show,
        ),
      ],
    );
  }
}

class TitleRow extends StatelessWidget {
  final String text;
  TitleRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(
        text,
        style: Theme.of(context).textTheme.headline3,
        textAlign: TextAlign.left,
      )),
    ]);
  }
}

class BodyRow extends StatelessWidget {
  final String text;
  BodyRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(
        text,
        style: Theme.of(context).textTheme.bodyText2,
        textAlign: TextAlign.left,
      )),
    ]);
  }
}

class StringValueRow extends StatelessWidget {
  final String label;
  final String value;
  StringValueRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label + " " + value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyText2),
        ),
      ],
    );
  }
}

class TimestampRow extends StatelessWidget {
  final String label;
  final Timestamp time;
  TimestampRow(this.label, this.time);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label + " " + format(time),
            textAlign: TextAlign.left,
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}
