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

import 'grpc_client.dart';
import 'package:flutter/material.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pb.dart';
import 'package:catalog/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pbgrpc.dart';

RegistryClient getClient() => RegistryClient(createClientChannel());

class RegistryProvider extends InheritedWidget {
  final Registry registry;

  const RegistryProvider(
      {Key key, @required this.registry, @required Widget child})
      : assert(registry != null),
        assert(child != null),
        super(key: key, child: child);

  static Registry of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RegistryProvider>()?.registry;

  @override
  bool updateShouldNotify(RegistryProvider oldWidget) =>
      registry != oldWidget.registry;
}

class Registry {
  Map<String, ProjectManager> projectManagers = Map();
  Map<String, ApiManager> apiManagers = Map();
  Map<String, VersionManager> versionManagers = Map();
  Map<String, SpecManager> specManagers = Map();

  ProjectManager getProjectManager(String name) {
    if (projectManagers[name] == null) {
      projectManagers[name] = ProjectManager(name);
    }
    return projectManagers[name];
  }

  ApiManager getApiManager(String name) {
    if (apiManagers[name] == null) {
      apiManagers[name] = ApiManager(name);
    }
    return apiManagers[name];
  }

  VersionManager getVersionManager(String name) {
    if (versionManagers[name] == null) {
      versionManagers[name] = VersionManager(name);
    }
    return versionManagers[name];
  }

  SpecManager getSpecManager(String name) {
    if (specManagers[name] == null) {
      specManagers[name] = SpecManager(name);
    }
    return specManagers[name];
  }
}

class ProjectManager extends ChangeNotifier {
  final String name;
  ProjectManager(this.name);
  Project _value;
  Future<Project> _future;

  void _fetch() {
    if (name == null) return;
    final client = getClient();
    final request = GetProjectRequest();
    request.name = name;
    try {
      _future = client.getProject(request, options: callOptions());
      _future.then((Project value) {
        _value = value;
        _future = null;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }

  Project get value {
    if (_value != null) {
      return _value;
    }
    if (_future == null) {
      _fetch();
    }
    return null;
  }
}

class ApiManager extends ChangeNotifier {
  final String name;
  ApiManager(this.name);
  Api _value;
  Future<Api> _future;

  void fetch() {
    if (name == "") return;
    final client = getClient();
    final request = GetApiRequest();
    request.name = name;
    try {
      _future = client.getApi(request, options: callOptions());
      _future.then((Api value) {
        _value = value;
        _future = null;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }

  Api get value {
    if (_value != null) {
      return _value;
    }
    if (_future == null) {
      fetch();
    }
    return null;
  }
}

class VersionManager extends ChangeNotifier {
  final String name;
  VersionManager(this.name);
  Version _value;
  Future<Version> _future;

  void _fetch() {
    if (name == "") return;
    final client = getClient();
    final request = GetVersionRequest();
    request.name = name;
    try {
      _future = client.getVersion(request, options: callOptions());
      _future.then((Version value) {
        _value = value;
        _future = null;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }

  Version get value {
    if (_value != null) {
      return _value;
    }
    if (_future == null) {
      _fetch();
    }
    return null;
  }
}

class SpecManager extends ChangeNotifier {
  final String name;
  SpecManager(this.name);
  Spec _value;
  Future<Spec> _future;
  void _fetch() {
    if (name == "") return;

    final client = getClient();
    final request = GetSpecRequest();
    request.name = name;
    try {
      _future = client.getSpec(request, options: callOptions());
      _future.then((Spec value) {
        _value = value;
        _future = null;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }

  Spec get value {
    if (_value != null) {
      return _value;
    }
    if (_future == null) {
      _fetch();
    }
    return null;
  }
}
