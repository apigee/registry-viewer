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
import 'info.dart';

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
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ApiInfoWidget(api),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ApiInfoWidget extends StatelessWidget {
  final Api api;
  ApiInfoWidget(this.api);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResourceNameButtonRow(
          api.name.split("/").sublist(2).join("/"),
          () {
            Navigator.pushNamed(
              context,
              api.routeNameForDetail(),
              arguments: api,
            );
          },
        ),
        SizedBox(height: 10),
        TitleRow(api.displayName),
        SizedBox(height: 10),
        BodyRow(api.description),
        SizedBox(height: 10),
        TimestampRow("created", api.createTime),
        TimestampRow("updated", api.updateTime),
      ],
    );
  }
}
