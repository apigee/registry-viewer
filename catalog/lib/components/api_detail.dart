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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/selection.dart';
import '../models/api.dart';

// ApiDetailCard is a card that displays details about a api.
class ApiDetailCard extends StatefulWidget {
  _ApiDetailCardState createState() => _ApiDetailCardState();
}

class _ApiDetailCardState extends State<ApiDetailCard> {
  String apiName = "";
  Api api;

  @override
  void didChangeDependencies() {
    SelectionProvider.of(context).api.addListener(() => setState(() {
          apiName = SelectionProvider.of(context).api.value;
          if (apiName == null) {
            apiName = "";
          }
          this.api = null;
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (api == null) {
      if (apiName != "") {
        // we need to fetch the api from the API
        ApiService().getApi(apiName).then((api) {
          setState(() {
            this.api = api;
          });
        });
      }
      return Card();
    } else {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text("$api"),
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                TextButton(
                  child: Text("API Details"),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      api.routeNameForDetail(),
                      arguments: api,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
