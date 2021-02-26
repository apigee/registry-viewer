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
import 'grpc_client.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_models.pb.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_service.pb.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1/registry_service.pbgrpc.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../generated/google/protobuf/field_mask.pb.dart';
import '../helpers/errors.dart';
import 'package:flutter/material.dart';
import '../models/artifact.dart';

const int pageSize = 50;

RegistryClient getClient() => RegistryClient(createClientChannel());

class StatusService {
  Future<Status> getStatus() {
    try {
      final client = getClient();
      final request = Empty();
      return client.getStatus(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class ProjectService {
  String filter;
  Map<int, String> tokens;
  Function onError;

  Future<List<Project>> getProjectsPage(int pageIndex) {
    return _getProjects(offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Project>> _getProjects({offset: int, limit: int}) async {
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListProjectsRequest();
    request.pageSize = limit;

    if (filter != null) {
      request.filter = filter;
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

  Future<Project> getProject(String name) {
    final client = getClient();
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
  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String projectName;

  Future<List<Api>> getApisPage(int pageIndex) {
    return _getApis(
        parent: projectName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Api>> _getApis({parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListApisRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter;
    }
    final token = tokens[offset];
    if (token != null) {
      request.pageToken = token;
    }
    try {
      final response = await client.listApis(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.apis;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<Api> getApi(String name) {
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

  Future<Api> updateApi(Api api, List<String> paths) {
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
  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String apiName;

  Future<List<ApiVersion>> getVersionsPage(int pageIndex) {
    return _getVersions(
        parent: apiName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<ApiVersion>> _getVersions(
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
      request.filter = filter;
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

  Future<ApiVersion> getVersion(String name) {
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

  Future<List<ApiVersion>> getVersions(String parent) async {
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
  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String versionName;
  SpecService();

  Future<List<ApiSpec>> getSpecsPage(int pageIndex) {
    return _getSpecs(
        parent: versionName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<ApiSpec>> _getSpecs(
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
      request.filter = filter;
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

  Future<ApiSpec> getSpec(String name) {
    final client = getClient();
    final request = GetApiSpecRequest();
    request.name = name;
    request.view = View.FULL;
    try {
      return client.getApiSpec(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class ArtifactService {
  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String parentName;

  Future<List<Artifact>> getArtifactsPage(int pageIndex) {
    return _getArtifacts(
        parent: parentName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Artifact>> _getArtifacts(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListArtifactsRequest();
    request.parent = parent;
    request.pageSize = limit;
    if (filter != null) {
      request.filter = filter;
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

  Future<Artifact> create(Artifact artifact) {
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
