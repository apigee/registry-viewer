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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'helpers/extensions.dart';

import 'pages/project_list.dart';
import 'pages/project_detail.dart';
import 'pages/api_list.dart';
import 'pages/api_detail.dart';
import 'pages/version_list.dart';
import 'pages/version_detail.dart';
import 'pages/spec_list.dart';
import 'pages/spec_detail.dart';
import 'pages/signin.dart';
import 'pages/home.dart';

class RegistryRouter {
  RegExp projectDetailRegExp,
      apiListRegExp,
      apiDetailRegExp,
      versionListRegExp,
      versionDetailRegExp,
      specListRegExp,
      specDetailRegExp;

  RegistryRouter() {
    // build patterns
    const namePattern = r"([a-zA-Z0-9-_\.]+)";
    const projectPattern = r"^/" + namePattern;
    const apisPattern = projectPattern + r"/apis";
    const apiPattern = apisPattern + r"/" + namePattern;
    const versionsPattern = apiPattern + r"/versions";
    const versionPattern = versionsPattern + r"/" + namePattern;
    const specsPattern = versionPattern + r"/specs";
    const specPattern = specsPattern + r"/" + namePattern;
    const endPattern = r"$";
    // use patterns to build regular expressions
    projectDetailRegExp = RegExp(projectPattern + endPattern);
    apiListRegExp = RegExp(apisPattern + endPattern);
    apiDetailRegExp = RegExp(apiPattern + endPattern);
    versionListRegExp = RegExp(versionsPattern + endPattern);
    versionDetailRegExp = RegExp(versionPattern + endPattern);
    specListRegExp = RegExp(specsPattern + endPattern);
    specDetailRegExp = RegExp(specPattern + endPattern);
  }

  MaterialPageRoute generateRoute(RouteSettings settings) {
    print(settings.name);
    if (kIsWeb) {
      if ((settings.name == "/") ||
          (currentUser == null) ||
          (currentUserIsAuthorized == false)) {
        return signInPage(settings);
      }
    } else {
      if (settings.name == "/") {
        return homePage(settings);
      }
    }
    // handle exact string patterns first.
    if (settings.name == "/projects") {
      return projectListPage(settings);
    } else if (settings.name == "/settings") {
      return settingsPage(settings);
    }
    // handle regex patterns next, watch for possible ordering sensitivities
    if (specDetailRegExp.hasMatch(settings.name)) {
      return specPage(settings);
    } else if (specListRegExp.hasMatch(settings.name)) {
      return specsPage(settings);
    } else if (versionDetailRegExp.hasMatch(settings.name)) {
      return versionPage(settings);
    } else if (versionListRegExp.hasMatch(settings.name)) {
      return versionsPage(settings);
    } else if (apiDetailRegExp.hasMatch(settings.name)) {
      return apiPage(settings);
    } else if (apiListRegExp.hasMatch(settings.name)) {
      return apisPage(settings);
    } else if (projectDetailRegExp.hasMatch(settings.name)) {
      return projectPage(settings);
    }
    // if nothing matches, display a "not found" page.
    return notFoundPage(settings);
  }
}

MaterialPageRoute signInPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return SignInPage();
    },
  );
}

MaterialPageRoute homePage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return HomePage();
    },
  );
}

MaterialPageRoute projectListPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return ProjectListPage();
    },
  );
}

MaterialPageRoute projectPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return ProjectDetailPage(settings.arguments, settings.name);
      });
}

MaterialPageRoute apisPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      final projectID = settings.name.split("/")[1];
      return ApiListPage(title: 'Apis', projectID: projectID);
    },
  );
}

MaterialPageRoute apiPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return ApiDetailPage(settings.arguments, settings.name);
      });
}

MaterialPageRoute versionsPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      final apiID = settings.name.allButLast("/");
      return VersionListPage(title: 'Versions', apiID: apiID);
    },
  );
}

MaterialPageRoute versionPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return VersionDetailPage(settings.arguments, settings.name);
      });
}

MaterialPageRoute specsPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      final versionID = settings.name.allButLast("/");
      return SpecListPage(title: 'Specs', versionID: versionID);
    },
  );
}

MaterialPageRoute specPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return SpecDetailPage(settings.arguments, settings.name);
      });
}

MaterialPageRoute notFoundPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NOT FOUND'),
          ),
          body: Center(
            child: Text("You were sent to a page that doesn't exist."),
          ),
        );
      });
}

MaterialPageRoute settingsPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings Page'),
        ),
      );
    },
  );
}
