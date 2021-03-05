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

import 'package:registry/registry.dart' as rpc;

void main(List<String> arguments) async {
  var projects = 0;
  await rpc.listProjects(f: (api) {
    projects++;
  });
  print("$projects projects");

  var apis = 0;
  await rpc.listAPIs(
      parent: 'projects/-',
      f: (api) {
        apis++;
      });
  print("$apis apis");

  var versions = 0;
  await rpc.listAPIVersions(
      parent: 'projects/-/apis/-',
      f: (version) {
        versions++;
      });
  print("$versions versions");

  var specs = 0;
  await rpc.listAPISpecs(
      parent: 'projects/-/apis/-/versions/-',
      f: (spec) {
        specs++;
      });
  print("$specs specs");
}
