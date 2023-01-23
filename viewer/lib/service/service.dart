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

import 'dart:async';
import 'package:registry/registry.dart';
import '../helpers/errors.dart';
import 'package:flutter/material.dart';
import '../models/artifact.dart';
import '../helpers/root.dart';

const int pageSize = 50;

RegistryClient getClient() => RegistryClient(createClientChannel());

AdminClient? getAdminClient() {
  if (root() == "/") {
    return AdminClient(createClientChannel());
  }
  return null;
}

class StatusService {
  Future<Status>? getStatus() {
    try {
      final client = getAdminClient();
      if (client == null) {
        return Future.value(Status(message: "ok"));
      }
      return client.getStatus(Empty(), options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class ProjectService {
  String? filter;
  late Map<int?, String> tokens;
  late Function onError;

  Future<List<Project>> getProjectsPage(int pageIndex) {
    return _getProjects(offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Project>> _getProjects({offset: int, limit: int}) async {
    if (offset == 0) {
      tokens = Map();
    }
    final client = getAdminClient()!;
    final request = ListProjectsRequest();
    request.pageSize = limit;
    request.orderBy = "display_name";

    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response =
          await client.listProjects(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.projects;
    } catch (err) {
      onError();
      throw err;
    }
  }

  Future<Project>? getProject(String name) {
    final client = getAdminClient();
    if (client == null) {
      return Future.value(Project(name: name));
    }
    final request = GetProjectRequest();
    request.name = name;
    try {
      return client.getProject(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class ApiService {
  BuildContext? context;
  String? filter;
  late Map<int?, String> tokens;
  late Map<int, List<Api>> carry;
  String? projectName;

  Future<List<Api>?> getApisPage(int pageIndex) {
    return _getApis(
        parent: projectName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Api>?> _getApis({parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
      carry = Map();
    }
    final client = getClient();
    final request = ListApisRequest();
    request.parent = parent + "/locations/global";
    request.orderBy = "display_name";
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    List<Api> apis = [];
    if (carry[offset] != null) {
      apis.addAll(carry[offset]!);
    }
    try {
      var response = await client.listApis(request, options: callOptions());
      apis.addAll(response.apis);
      while ((apis.length < limit) && (response.nextPageToken != "")) {
        request.pageToken = response.nextPageToken;
        response = await client.listApis(request, options: callOptions());
        apis.addAll(response.apis);
        if (response.nextPageToken == "" ||
            response.nextPageToken == request.pageToken) {
          break;
        }
      }
      tokens[offset + limit] = response.nextPageToken;
      if (apis.length > limit) {
        carry[offset] = apis.sublist(limit);
        apis = apis.sublist(0, limit);
      }
      return apis;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<Api>? getApi(String name) {
    final client = getClient();
    final request = GetApiRequest();
    request.name = name;
    try {
      return client.getApi(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }

  Future<Api>? updateApi(Api api, List<String> paths) {
    final client = getClient();
    final request = UpdateApiRequest();
    request.api = api;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    try {
      return client.updateApi(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class VersionService {
  BuildContext? context;
  String? filter;
  late Map<int?, String> tokens;
  String? apiName;

  Future<List<ApiVersion>?> getVersionsPage(int pageIndex) {
    return _getVersions(
        parent: apiName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<ApiVersion>?> _getVersions(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListApiVersionsRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response =
          await client.listApiVersions(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.apiVersions;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<ApiVersion>? getVersion(String name) {
    final client = getClient();
    final request = GetApiVersionRequest();
    request.name = name;
    try {
      return client.getApiVersion(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }

  Future<List<ApiVersion>?> getVersions(String parent) async {
    final client = getClient();
    final request = ListApiVersionsRequest();
    request.parent = parent;
    request.pageSize = 20;
    try {
      final response =
          await client.listApiVersions(request, options: callOptions());
      return response.apiVersions;
    } catch (err) {
      return null;
    }
  }
}

class SpecService {
  BuildContext? context;
  String? filter;
  late Map<int?, String> tokens;
  String? versionName;
  SpecService();

  Future<List<ApiSpec>?> getSpecsPage(int pageIndex) {
    return _getSpecs(
        parent: versionName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<ApiSpec>?> _getSpecs(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListApiSpecsRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response =
          await client.listApiSpecs(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.apiSpecs;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }
}

class DeploymentService {
  BuildContext? context;
  String? filter;
  late Map<int?, String> tokens;
  String? apiName;

  Future<List<ApiDeployment>?> getDeploymentsPage(int pageIndex) {
    return _getDeployments(
        parent: apiName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<ApiDeployment>?> _getDeployments(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListApiDeploymentsRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response =
          await client.listApiDeployments(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.apiDeployments;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<ApiDeployment>? getDeployment(String name) {
    final client = getClient();
    final request = GetApiDeploymentRequest();
    request.name = name;
    try {
      return client.getApiDeployment(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }

  Future<List<ApiDeployment>?> getDeployments(String parent) async {
    final client = getClient();
    final request = ListApiDeploymentsRequest();
    request.parent = parent;
    request.pageSize = 20;
    try {
      final response =
          await client.listApiDeployments(request, options: callOptions());
      return response.apiDeployments;
    } catch (err) {
      return null;
    }
  }
}

class ArtifactService {
  BuildContext? context;
  String? filter;
  late Map<int?, String> tokens;
  String? parentName;

  Future<List<Artifact>?> getArtifactsPage(int pageIndex) {
    return _getArtifacts(
        parent: parentName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Artifact>?> _getArtifacts(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (parent.split("/").length == 2) {
      parent += "/locations/global";
    }
    if (offset == 0) {
      tokens = Map();
    }

    final client = getClient();
    final request = ListArtifactsRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter!;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response =
          await client.listArtifacts(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.artifacts;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<Artifact>? create(Artifact artifact) {
    final client = getClient();
    final request = CreateArtifactRequest();
    request.artifact = artifact;
    request.artifactId = artifact.relation;
    request.parent = artifact.subject;
    try {
      return client.createArtifact(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}
