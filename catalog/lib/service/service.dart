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
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pb.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pbgrpc.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../helpers/errors.dart';
import 'package:flutter/material.dart';

const int pageSize = 50;

class StatusService {
  RegistryClient getClient() => RegistryClient(createClientChannel());

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
  RegistryClient getClient() => RegistryClient(createClientChannel());

  BuildContext context;
  String filter;
  Map<int, String> tokens;

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
      reportError(context, err);
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
  RegistryClient getClient() => RegistryClient(createClientChannel());

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
}

class VersionService {
  RegistryClient getClient() => RegistryClient(createClientChannel());

  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String apiName;

  Future<List<Version>> getVersionsPage(int pageIndex) {
    return _getVersions(
        parent: apiName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Version>> _getVersions(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListVersionsRequest();
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
          await client.listVersions(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.versions;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<Version> getVersion(String name) {
    final client = getClient();
    final request = GetVersionRequest();
    request.name = name;
    try {
      return client.getVersion(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }

  Future<List<Version>> getVersions(String parent) async {
    final client = getClient();
    final request = ListVersionsRequest();
    request.parent = parent;
    request.pageSize = 20;
    try {
      final response =
          await client.listVersions(request, options: callOptions());
      return response.versions;
    } catch (err) {
      return null;
    }
  }
}

class SpecService {
  RegistryClient getClient() => RegistryClient(createClientChannel());

  BuildContext context;
  String filter;
  Map<int, String> tokens;
  String versionName;
  SpecService();

  Future<List<Spec>> getSpecsPage(int pageIndex) {
    return _getSpecs(
        parent: versionName, offset: pageIndex * pageSize, limit: pageSize);
  }

  Future<List<Spec>> _getSpecs(
      {parent: String, offset: int, limit: int}) async {
    if (parent == "") {
      return null;
    }
    if (offset == 0) {
      tokens = Map();
    }
    final client = getClient();
    final request = ListSpecsRequest();
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
      final response = await client.listSpecs(request, options: callOptions());
      tokens[offset + limit] = response.nextPageToken;
      return response.specs;
    } catch (err) {
      reportError(context, err);
      throw err;
    }
  }

  Future<Spec> getSpec(String name) {
    final client = getClient();
    final request = GetSpecRequest();
    request.name = name;
    request.view = View.FULL;
    try {
      return client.getSpec(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}

class PropertiesService {
  static RegistryClient getClient() => RegistryClient(createClientChannel());

  static Future<ListPropertiesResponse> listProperties(String parent,
      {subject: String}) {
    final client = getClient();
    final request = ListPropertiesRequest();
    request.parent = subject;
    try {
      return client.listProperties(request, options: callOptions());
    } catch (err) {
      print('Caught error: $err');
      return null;
    }
  }
}
