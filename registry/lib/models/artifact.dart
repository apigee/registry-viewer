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

import 'dart:convert';
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_models.pb.dart';

extension Display on Artifact {
  String nameForDisplay() {
    return this.name.split("/").last;
  }

  String routeNameForDetail() {
    return "/" + this.name;
  }

  String get subject {
    final parts = this.name.split("/");
    return parts.sublist(0, parts.length - 2).join("/");
  }

  String get relation {
    final parts = this.name.split("/");
    return parts[parts.length - 1];
  }

  String get stringValue {
    if (this.mimeType == "text/plain") {
      final codec = Utf8Codec();
      return codec.decode(this.contents);
    }
    return "";
  }

  set stringValue(String value) {
    this.mimeType = "text/plain";
    final codec = Utf8Codec();
    this.contents = codec.encode(value);
  }
}
