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
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:registry/registry.dart';
import '../helpers/timestamp.dart';

Function? onlyIf(bool? condition, Function action) {
  if (condition == null || !condition) {
    return null;
  }
  return action;
}

class ResourceNameButtonRow extends StatelessWidget {
  final String? name;
  final void Function()? show;
  final void Function()? edit;
  const ResourceNameButtonRow({this.name, this.show, this.edit, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (show == null)
            Flexible(
              child: Text(
                name!,
                style: Theme.of(context).textTheme.bodyLarge,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          if (show != null)
            Flexible(
              child: GestureDetector(
                onTap: show,
                child: Text(
                  name!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Theme.of(context).primaryColor),
                  softWrap: false,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          if (edit != null)
            GestureDetector(
              onTap: edit != null ? edit : () {},
              child: Text(
                "EDIT",
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).primaryColor),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

class PanelNameRow extends StatelessWidget {
  final String? name;
  final Widget? button;
  const PanelNameRow({this.name, this.button, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Text(
              name!,
              style: Theme.of(context).textTheme.bodyLarge,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
          (button != null) ? button! : const SizedBox(width: 0, height: 0),
        ],
      ),
    );
  }
}

class TitleRow extends StatelessWidget {
  final String text;
  final Function? action;
  const TitleRow(this.text, {this.action, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        action != null
            ? Expanded(
                child: GestureDetector(
                  onTap: action as void Function()?,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Theme.of(context).primaryColor),
                    textAlign: TextAlign.left,
                    softWrap: true,
                  ),
                ),
              )
            : Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.left,
                  softWrap: true,
                ),
              ),
      ],
    );
  }
}

class SuperTitleRow extends StatelessWidget {
  final String text;
  const SuperTitleRow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge!
            .copyWith(color: Colors.grey[500]),
        textAlign: TextAlign.left,
        softWrap: true,
      )),
    ]);
  }
}

class BodyRow extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool wrap;
  const BodyRow(this.text, {this.style, this.wrap = false, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(
          text,
          style: style ?? Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.left,
          softWrap: wrap,
        ),
      ),
    ]);
  }
}

class LinkifiedBodyRow extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const LinkifiedBodyRow(this.text, {this.style, super.key});
  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Linkify(
      onOpen: (link) async {
        if (await canLaunchUrl(Uri.parse(link.url))) {
          await launchUrl(Uri.parse(link.url));
        } else {
          throw 'Could not launch $link';
        }
      },
      text: text,
      textAlign: TextAlign.left,
      style: textStyle,
      linkStyle: textStyle.copyWith(color: Theme.of(context).primaryColor),
      softWrap: false,
      overflow: TextOverflow.clip,
    );
  }
}

class LinkRow extends StatelessWidget {
  final String text;
  final String url;
  const LinkRow(this.text, this.url, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            child: Text(
              text,
              style: GoogleFonts.inconsolata()
                  .copyWith(color: Theme.of(context).primaryColor),
              textAlign: TextAlign.left,
            ),
            onTap: () async {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
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
  const StringValueRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label + " " + value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class TimestampRow extends StatelessWidget {
  final Timestamp created;
  final Timestamp updated;
  const TimestampRow(this.created, this.updated, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                "created " + format(created),
                textAlign: TextAlign.left,
                style: GoogleFonts.inconsolata(),
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Flexible(
              child: Text(
                "updated " + format(updated),
                textAlign: TextAlign.left,
                style: GoogleFonts.inconsolata(),
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String text;
  const DetailRow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Divider(thickness: 2),
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

class LabelsRow extends StatelessWidget {
  final Map<String, String> map;
  final TextStyle? style;
  const LabelsRow(this.map, {this.style, super.key});
  @override
  Widget build(BuildContext context) {
    var keys = map.keys.toList();
    keys.sort();
    return Wrap(
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: <Widget>[
        for (var key in keys)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            color: Theme.of(context).primaryColorLight,
            child: Text(labelText(key, map[key])),
          ),
      ],
    );
  }

  static String labelText(String key, value) {
    if (value == "true") {
      return key;
    } else if (value == "false") {
      return "!" + key;
    }
    return key + ":" + value;
  }
}

class AnnotationsRow extends StatelessWidget {
  final Map<String, String> map;
  final TextStyle? style;
  const AnnotationsRow(this.map, {this.style, super.key});
  @override
  Widget build(BuildContext context) {
    var keys = map.keys.toList();
    keys.sort();
    return Wrap(
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: <Widget>[
        for (var key in keys)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            color: Theme.of(context).primaryColorLight,
            child: Text(key + ":" + map[key]!),
          ),
      ],
    );
  }
}

class PageSection extends StatelessWidget {
  final List<Widget>? children;
  const PageSection({this.children, super.key});
  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    rows.add(const SizedBox(height: 10));
    rows.addAll(children!);
    return Column(
      children: rows,
    );
  }
}
