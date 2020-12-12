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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pb.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_service.pbgrpc.dart';
import '../generated/google/protobuf/field_mask.pb.dart';

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
  Map<String, PropertyManager> propertyManagers = Map();
  Map<String, LabelManager> labelManagers = Map();

  ProjectManager getProjectManager(String name) {
    Manager.removeUnused(projectManagers);
    if (projectManagers[name] == null) {
      projectManagers[name] = ProjectManager(name);
    }
    return projectManagers[name];
  }

  ApiManager getApiManager(String name) {
    Manager.removeUnused(apiManagers);
    if (apiManagers[name] == null) {
      apiManagers[name] = ApiManager(name);
    }
    return apiManagers[name];
  }

  VersionManager getVersionManager(String name) {
    Manager.removeUnused(versionManagers);
    if (versionManagers[name] == null) {
      versionManagers[name] = VersionManager(name);
    }
    return versionManagers[name];
  }

  SpecManager getSpecManager(String name) {
    Manager.removeUnused(specManagers);
    if (specManagers[name] == null) {
      specManagers[name] = SpecManager(name);
    }
    return specManagers[name];
  }

  PropertyManager getPropertyManager(String name) {
    Manager.removeUnused(propertyManagers);
    if (propertyManagers[name] == null) {
      propertyManagers[name] = PropertyManager(name);
    }
    return propertyManagers[name];
  }

  LabelManager getLabelManager(String name) {
    Manager.removeUnused(labelManagers);
    if (labelManagers[name] == null) {
      labelManagers[name] = LabelManager(name);
    }
    return labelManagers[name];
  }
}

// A Manager is a ChangeNotifier that we use to get and manage a resource.
// When managers are unused, we delete them.
class Manager extends ChangeNotifier {
  bool get isUnused {
    return !hasListeners;
  }

  static void removeUnused(Map<String, Manager> managers) {
    List<String> names = List();
    managers.forEach((name, m) {
      if (m.isUnused) {
        names.add(name);
      }
    });
    names.forEach((name) {
      managers.remove(name);
    });
  }
}

// A ResourceManager gets and updates a resource of a specific type.
abstract class ResourceManager<T> extends Manager {
  final String name;
  ResourceManager(this.name);
  T _value;
  Future<T> _future;

  T get value {
    if (_value != null) {
      return _value;
    }
    if (_future == null) {
      _fetch();
    }
    return null;
  }

  void _fetch() {
    if (name == "") return;
    final client = getClient();
    try {
      _future = fetchFuture(client);
      _future.then((T value) {
        _value = value;
        _future = null;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }

  // fetchFuture must be overridden to return a future for the fetched resource.
  Future<T> fetchFuture(RegistryClient client);
}

class ProjectManager extends ResourceManager<Project> {
  ProjectManager(String name) : super(name);
  Future<Project> fetchFuture(RegistryClient client) {
    final request = GetProjectRequest();
    request.name = name;
    return client.getProject(request, options: callOptions());
  }

  void update(Project newValue, List<String> paths) {
    final client = getClient();
    final request = UpdateProjectRequest();
    request.project = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    try {
      client.updateProject(request, options: callOptions()).then((value) {
        _value = value;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }
}

class ApiManager extends ResourceManager<Api> {
  ApiManager(String name) : super(name);
  Future<Api> fetchFuture(RegistryClient client) {
    final request = GetApiRequest();
    request.name = name;
    return client.getApi(request, options: callOptions());
  }

  void update(Api newValue, List<String> paths) {
    final client = getClient();
    final request = UpdateApiRequest();
    request.api = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    try {
      client.updateApi(request, options: callOptions()).then((value) {
        _value = value;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }
}

class VersionManager extends ResourceManager<Version> {
  VersionManager(String name) : super(name);
  Future<Version> fetchFuture(RegistryClient client) {
    final request = GetVersionRequest();
    request.name = name;
    return client.getVersion(request, options: callOptions());
  }

  void update(Version newValue, List<String> paths) {
    final client = getClient();
    final request = UpdateVersionRequest();
    request.version = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    try {
      client.updateVersion(request, options: callOptions()).then((value) {
        _value = value;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }
}

class SpecManager extends ResourceManager<Spec> {
  SpecManager(String name) : super(name);
  Future<Spec> fetchFuture(RegistryClient client) {
    final request = GetSpecRequest();
    request.name = name;
    return client.getSpec(request, options: callOptions());
  }

  void update(Spec newValue, List<String> paths) {
    final client = getClient();
    final request = UpdateSpecRequest();
    request.spec = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    try {
      client.updateSpec(request, options: callOptions()).then((value) {
        _value = value;
        notifyListeners();
      });
    } catch (err) {
      print('Caught error: $err');
    }
  }
}

class PropertyManager extends ResourceManager<Property> {
  PropertyManager(String name) : super(name);
  Future<Property> fetchFuture(RegistryClient client) {
    final request = GetPropertyRequest();
    request.name = name;
    request.view = View.FULL;
    return client.getProperty(request, options: callOptions());
  }

  Future<Property> update(Property newValue) {
    final client = getClient();
    final request = UpdatePropertyRequest();
    request.property = newValue;
    try {
      return client
          .updateProperty(request, options: callOptions())
          .then((value) {
        _value = value;
        notifyListeners();
        return value;
      });
    } catch (err) {
      print('Caught error: $err');
    }
    return null;
  }

  Future delete(String name) {
    final request = DeletePropertyRequest();
    request.name = name;
    return getClient()
        .deleteProperty(request, options: callOptions())
        .then((empty) => Future);
  }
}

class LabelManager extends ResourceManager<Label> {
  LabelManager(String name) : super(name);
  Future<Label> fetchFuture(RegistryClient client) {
    final request = GetLabelRequest();
    request.name = name;
    return client.getLabel(request, options: callOptions());
  }

  Future delete(String name) {
    final request = DeleteLabelRequest();
    request.name = name;
    return getClient()
        .deleteLabel(request, options: callOptions())
        .then((empty) => Future);
  }
}
