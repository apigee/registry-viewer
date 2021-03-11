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

import 'package:grpc/grpc.dart' as grpc;
import 'package:registry/registry.dart' as rpc;

class GoogleApis {
  static String idForTitle(String title) {
    var id = title.toLowerCase();
    // remove the google prefix because it is applied inconsistently
    if (id.startsWith("google ")) {
      id = id.substring("google ".length);
    }
    // remove anything in parentheses
    if (id.contains("(")) {
      final start = id.indexOf("(");
      final end = id.indexOf(")");
      id = id.substring(0, start - 1) + id.substring(end + 1);
    }
    // remove some superfluous words
    if (id.contains(" api")) {
      id = id.replaceAll(" api", "");
    }
    if (id.contains(" v2")) {
      id = id.replaceAll(" v2", "");
    }
    if (id.contains(" v3")) {
      id = id.replaceAll(" v3", "");
    }
    // make it printable
    id = id.replaceAll("&", "and");
    id = id.replaceAll("/", "");
    id = id.replaceAll(" ", "-");
    // consistently prefix with "google-"
    id = "google-" + id;
    return id;
  }

  static String titleForTitle(String title) {
    if (!title.startsWith("Google ")) {
      title = "Google " + title;
    }
    return title;
  }
}

extension Importing on rpc.RegistryClient {
  Future<bool> projectExists(String name) async {
    try {
      await this.getProject(rpc.GetProjectRequest()..name = name);
      return true;
    } on grpc.GrpcError catch (error) {
      if (error.code == grpc.StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> apiExists(String name) async {
    try {
      await this.getApi(rpc.GetApiRequest()..name = name);
      return true;
    } on grpc.GrpcError catch (error) {
      if (error.code == grpc.StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> apiVersionExists(String name) async {
    try {
      await this.getApiVersion(rpc.GetApiVersionRequest()..name = name);
      return true;
    } on grpc.GrpcError catch (error) {
      if (error.code == grpc.StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> apiSpecExists(String name) async {
    try {
      await this.getApiSpec(rpc.GetApiSpecRequest()..name = name);
      return true;
    } on grpc.GrpcError catch (error) {
      if (error.code == grpc.StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  void ensureProjectExists(rpc.Project project) async {
    if (!await this.projectExists(project.name)) {
      await this.createProject(rpc.CreateProjectRequest()
        ..projectId = project.name.split("/").last
        ..project = project);
    }
  }

  void ensureApiExists(rpc.Api api) async {
    if (!await this.apiExists(api.name)) {
      await this.createApi(rpc.CreateApiRequest()
        ..parent = api.name.split("/").sublist(0, 2).join("/")
        ..apiId = api.name.split("/").last
        ..api = api);
    }
  }

  void ensureApiVersionExists(rpc.ApiVersion version) async {
    if (!await this.apiVersionExists(version.name)) {
      await this.createApiVersion(rpc.CreateApiVersionRequest()
        ..parent = version.name.split("/").sublist(0, 4).join("/")
        ..apiVersionId = version.name.split("/").last
        ..apiVersion = version);
    }
  }
}
