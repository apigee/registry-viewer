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

// Convert a widget name to the corresponding resource name.
String resourceNameForWidgetName(String name) {
  List parts = name.substring(1).split("/");
  parts.insert(2, "global");
  parts.insert(2, "locations");
  return parts.join("/");
}

String specRevisionNameForArtifactName(String name) {
  return name.split("/").sublist(0, 10).join("/");
}

String specNameForSpecRevisionName(String name) {
  return name.split("@")[0];
}
