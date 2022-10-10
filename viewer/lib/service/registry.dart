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

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:registry/registry.dart';
import '../helpers/root.dart';

RegistryClient getClient() => RegistryClient(createClientChannel());

AdminClient? getAdminClient() {
  if (root() == "/") {
    return AdminClient(createClientChannel());
  }
  return null;
}

class RegistryProvider extends InheritedWidget {
  final Registry registry;

  const RegistryProvider(
      {Key? key, required this.registry, required Widget child})
      : assert(registry != null),
        assert(child != null),
        super(key: key, child: child);

  static Registry? of(BuildContext context) =>
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
  Map<String?, ArtifactManager> artifactManagers = Map();

  ProjectManager? getProjectManager(String name) {
    Manager.removeUnused(projectManagers);
    if (projectManagers[name] == null) {
      projectManagers[name] = ProjectManager(name);
    }
    return projectManagers[name];
  }

  ApiManager? getApiManager(String name) {
    Manager.removeUnused(apiManagers);
    if (apiManagers[name] == null) {
      apiManagers[name] = ApiManager(name);
    }
    return apiManagers[name];
  }

  VersionManager? getVersionManager(String name) {
    Manager.removeUnused(versionManagers);
    if (versionManagers[name] == null) {
      versionManagers[name] = VersionManager(name);
    }
    return versionManagers[name];
  }

  SpecManager? getSpecManager(String name) {
    Manager.removeUnused(specManagers);
    if (specManagers[name] == null) {
      specManagers[name] = SpecManager(name);
    }
    return specManagers[name];
  }

  ArtifactManager? getArtifactManager(String? name) {
    Manager.removeUnused(artifactManagers);
    if (artifactManagers[name] == null) {
      artifactManagers[name] = ArtifactManager(name);
    }
    return artifactManagers[name];
  }
}

// A Manager is a ChangeNotifier that we use to get and manage a resource.
// When managers are unused, we delete them.
class Manager extends ChangeNotifier {
  bool get isUnused {
    return !hasListeners;
  }

  static void removeUnused(Map<String?, Manager> managers) {
    List<String?> names = [];
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
  final String? name;
  ResourceManager(this.name);
  T? _value;
  Future<T>? _future;

  T? get value {
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
    _future = fetchFuture(getClient(), getAdminClient());
    _future!.then((T value) {
      _value = value;
      _future = null;
      notifyListeners();
    });
  }

  // fetchFuture must be overridden to return a future for the fetched resource.
  Future<T> fetchFuture(RegistryClient client, AdminClient? adminClient);
}

class ProjectManager extends ResourceManager<Project> {
  ProjectManager(String name) : super(name);
  Future<Project> fetchFuture(RegistryClient client, AdminClient? adminClient) {
    final request = GetProjectRequest();
    request.name = name!;
    if (adminClient != null) {
      return adminClient.getProject(request, options: callOptions());
    }
    return Future.value(Project(name: name));
  }

  void update(Project newValue, List<String> paths, Function onError) {
    final adminClient = getAdminClient()!;
    final request = UpdateProjectRequest();
    request.project = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }

    adminClient.updateProject(request, options: callOptions()).then((value) {
      _value = value;
      notifyListeners();
    }).catchError((error) => onError(error));
  }
}

class ApiManager extends ResourceManager<Api> {
  ApiManager(String name) : super(name);
  Future<Api> fetchFuture(RegistryClient client, AdminClient? adminClient) {
    final request = GetApiRequest();
    request.name = name!;
    return client.getApi(request, options: callOptions());
  }

  void update(Api newValue, List<String> paths, Function onError) {
    final client = getClient();
    final request = UpdateApiRequest();
    request.api = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    client.updateApi(request, options: callOptions()).then((value) {
      _value = value;
      notifyListeners();
    }).catchError((error) => onError(error));
  }
}

class VersionManager extends ResourceManager<ApiVersion> {
  VersionManager(String name) : super(name);
  Future<ApiVersion> fetchFuture(
      RegistryClient client, AdminClient? adminClient) {
    final request = GetApiVersionRequest();
    request.name = name!;
    return client.getApiVersion(request, options: callOptions());
  }

  void update(ApiVersion newValue, List<String> paths, Function onError) {
    final client = getClient();
    final request = UpdateApiVersionRequest();
    request.apiVersion = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    client.updateApiVersion(request, options: callOptions()).then((value) {
      _value = value;
      notifyListeners();
    }).catchError((error) => onError(error));
  }
}

class SpecManager extends ResourceManager<ApiSpec> {
  SpecManager(String name) : super(name);
  Future<ApiSpec> fetchFuture(RegistryClient client, AdminClient? adminClient) {
    final request = GetApiSpecRequest();
    request.name = name!;
    return client.getApiSpec(request, options: callOptions()).then((spec) {
      final request = GetApiSpecContentsRequest();
      request.name = spec.name;
      return client
          .getApiSpecContents(request, options: callOptions())
          .then((contents) {
        if (spec.mimeType.contains("+gzip") &&
            !contents.contentType.contains("+gzip")) {
          spec.contents = GZipEncoder().encode(contents.data)!;
        } else {
          spec.contents = contents.data;
        }
        return spec;
      });
    });
  }

  void update(ApiSpec newValue, List<String> paths, Function onError) {
    final client = getClient();
    final request = UpdateApiSpecRequest();
    request.apiSpec = newValue;
    request.updateMask = FieldMask();
    for (String path in paths) {
      request.updateMask.paths.add(path);
    }
    client.updateApiSpec(request, options: callOptions()).then((value) {
      _value = value;
      notifyListeners();
    }).catchError((error) => onError(error));
  }
}

class ArtifactManager extends ResourceManager<Artifact> {
  ArtifactManager(String? name) : super(name);
  Future<Artifact> fetchFuture(RegistryClient client, AdminClient? adminClient) {
    final request = GetArtifactRequest();
    request.name = name!;
    return client.getArtifact(request, options: callOptions()).then((artifact) {
      final request = GetArtifactContentsRequest();
      request.name = artifact.name;
      return client
          .getArtifactContents(request, options: callOptions())
          .then((contents) {
        artifact.contents = contents.data;
        artifact.mimeType = contents.contentType;
        return artifact;
      });
    });
  }

  Future<Artifact> update(Artifact newValue, Function onError) {
    final client = getClient();
    final request = ReplaceArtifactRequest();
    request.artifact = newValue;
    return client
        .replaceArtifact(request, options: callOptions())
        .then((value) {
      _value = value;
      notifyListeners();
      return value;
    }).catchError((error) => onError(error));
  }

  Future delete(String name) {
    final request = DeleteArtifactRequest();
    request.name = name;
    return getClient()
        .deleteArtifact(request, options: callOptions())
        .then((empty) => Future);
  }
}
