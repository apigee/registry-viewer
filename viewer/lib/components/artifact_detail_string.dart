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
import 'package:registry/registry.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'detail_rows.dart';
import 'artifact_edit.dart';
import '../helpers/extensions.dart';
import '../models/selection.dart';
import '../models/artifact.dart';

class StringArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final Function? selflink;
  final bool? editable;
  StringArtifactCard(this.artifact, {this.selflink, this.editable});
  @override
  Widget build(BuildContext context) {
    Function? editableFn = onlyIf(editable, () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection!,
              child: AlertDialog(
                content: EditArtifactForm(),
              ),
            );
          });
    });

    final style = GoogleFonts.inconsolata();

    return Card(
      child: Column(
        children: [
          ResourceNameButtonRow(
              name: artifact.name.last(1),
              show: selflink as void Function()?,
              edit: editableFn as void Function()?),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                SizedBox(height: 30),
                Linkify(
                  onOpen: (link) async {
                    if (await canLaunchUrl(Uri.parse(link.url))) {
                      await launchUrl(Uri.parse(link.url));
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                  text: artifact.stringValue,
                  textAlign: TextAlign.left,
                  style: style,
                  linkStyle:
                      style.copyWith(color: Theme.of(context).primaryColorDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
