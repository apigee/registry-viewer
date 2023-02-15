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

import 'generated/google/cloud/apigeeregistry/v1/admin_service.pbgrpc.dart';
import 'generated/google/cloud/apigeeregistry/v1/registry_service.pbgrpc.dart';
import 'grpc_client.dart';

void nil() {}

Future<void> listProjects(AdminClient client,
    {Function f = nil, String filter = ''}) async {
  var request = ListProjectsRequest()
    ..filter = filter
    ..pageSize = 500;
  while (true) {
    var response = await client.listProjects(request, options: callOptions());
    for (var api in response.projects) {
      f(api);
    }
    if (response.nextPageToken == '') {
      break;
    }
    request.pageToken = response.nextPageToken;
  }
}

Future<void> listAPIs(RegistryClient client,
    {Function f = nil, String parent = '', String filter = ''}) async {
  var request = ListApisRequest()
    ..parent = parent
    ..filter = filter
    ..pageSize = 50;
  while (true) {
    var response = await client.listApis(request, options: callOptions());
    for (var api in response.apis) {
      await f(api);
    }
    if (response.nextPageToken == '') {
      break;
    }
    request.pageToken = response.nextPageToken;
  }
}

Future<void> listAPIVersions(RegistryClient client,
    {Function f = nil, String parent = '', String filter = ''}) async {
  var request = ListApiVersionsRequest()
    ..parent = parent
    ..filter = filter
    ..pageSize = 50;
  while (true) {
    var response =
        await client.listApiVersions(request, options: callOptions());
    for (var spec in response.apiVersions) {
      await f(spec);
    }
    if (response.nextPageToken == '') {
      break;
    }
    request.pageToken = response.nextPageToken;
  }
}

Future<void> listAPISpecs(RegistryClient client,
    {Function f = nil, String parent = '', String filter = ''}) async {
  var request = ListApiSpecsRequest()
    ..parent = parent
    ..filter = filter
    ..pageSize = 50;
  while (true) {
    var response = await client.listApiSpecs(request, options: callOptions());
    for (var spec in response.apiSpecs) {
      await f(spec);
    }
    if (response.nextPageToken == '') {
      break;
    }
    request.pageToken = response.nextPageToken;
  }
}
