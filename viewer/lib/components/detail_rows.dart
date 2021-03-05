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
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:registry/registry.dart';
import '../helpers/timestamp.dart';

Function onlyIf(bool condition, Function action) {
  if (condition == null || !condition) {
    return null;
  }
  return action;
}

class ResourceNameButtonRow extends StatelessWidget {
  final String name;
  final void Function() show;
  final void Function() edit;
  ResourceNameButtonRow({this.name, this.show, this.edit});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).secondaryHeaderColor,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (show == null)
            Flexible(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyText1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          if (show != null)
            Flexible(
              child: GestureDetector(
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(color: Theme.of(context).accentColor),
                  softWrap: false,
                  overflow: TextOverflow.clip,
                ),
                onTap: show,
              ),
            ),
          if (edit != null)
            GestureDetector(
              child: Text(
                "EDIT",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(color: Theme.of(context).accentColor),
                textAlign: TextAlign.right,
              ),
              onTap: edit != null ? edit : () {},
            ),
        ],
      ),
    );
  }
}

class PanelNameRow extends StatelessWidget {
  final String name;
  PanelNameRow({this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).secondaryHeaderColor,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyText1,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}

class TitleRow extends StatelessWidget {
  final String text;
  final Function action;
  TitleRow(this.text, {this.action});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        action != null
            ? Expanded(
                child: GestureDetector(
                    child: Text(
                      text,
                      style: Theme.of(context)
                          .textTheme
                          .headline3
                          .copyWith(color: Theme.of(context).accentColor),
                      textAlign: TextAlign.left,
                    ),
                    onTap: action),
              )
            : Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.left,
                ),
              ),
      ],
    );
  }
}

class SuperTitleRow extends StatelessWidget {
  final String text;
  SuperTitleRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .headline6
            .copyWith(color: Colors.grey[500]),
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
        style: Theme.of(context).textTheme.bodyText1,
        textAlign: TextAlign.left,
      )),
    ]);
  }
}

class SmallBodyRow extends StatelessWidget {
  final String text;
  SmallBodyRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(
        text,
        style: Theme.of(context).textTheme.bodyText2,
        textAlign: TextAlign.left,
        softWrap: false,
        overflow: TextOverflow.clip,
      )),
    ]);
  }
}

class LinkRow extends StatelessWidget {
  final String text;
  final String url;
  LinkRow(this.text, this.url);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(color: Theme.of(context).accentColor),
              textAlign: TextAlign.left,
            ),
            onTap: () async {
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
        ),
      ],
    );
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
  final Timestamp created;
  final Timestamp updated;
  TimestampRow(this.created, this.updated);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            "created " + format(created) + " | last updated " + format(updated),
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyText2,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String text;
  DetailRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Divider(thickness: 2),
            Text(
              text.trim(),
              style: GoogleFonts.robotoMono(color: Colors.grey[500]),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    ]);
  }
}
