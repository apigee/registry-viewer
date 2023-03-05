// Copyright 2023 Google LLC. All Rights Reserved.
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
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

// AboutCard is a card that displays details about this project.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).highlightColor,
      padding: const EdgeInsets.all(30.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: MarkdownBody(
                  data: aboutText,
                  onTapLink: (text, url, title) {
                    launchUrl(Uri.parse(url!));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const aboutText = """
# About the API Registry Viewer
 
The API Registry Viewer is a browser for the [Apigee Registry API](https://github.com/apigee/registry).

Source code for the viewer is in the [registry-viewer](https://github.com/apigee/registry-viewer)
repository on GitHub.

To learn more about the Registry API, visit [the project wiki](https://github.com/apigee/registry/wiki).
""";
