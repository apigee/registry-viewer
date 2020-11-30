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
  RegExp projectRegExp,
      apisRegExp,
      apiRegExp,
      versionsRegExp,
      versionRegExp,
      specsRegExp,
      specRegExp;

  RegistryRouter() {
    // build patterns
    const namePattern = r"([a-zA-Z0-9-_\.]+)";
    const projectsPattern = r"^/projects";
    const projectPattern = projectsPattern + r"/" + namePattern;
    const apisPattern = projectPattern + r"/apis";
    const apiPattern = apisPattern + r"/" + namePattern;
    const versionsPattern = apiPattern + r"/versions";
    const versionPattern = versionsPattern + r"/" + namePattern;
    const specsPattern = versionPattern + r"/specs";
    const specPattern = specsPattern + r"/" + namePattern;
    const endPattern = r"$";
    // use patterns to build regular expressions
    projectRegExp = RegExp(projectPattern + endPattern);
    apisRegExp = RegExp(apisPattern + endPattern);
    apiRegExp = RegExp(apiPattern + endPattern);
    versionsRegExp = RegExp(versionsPattern + endPattern);
    versionRegExp = RegExp(versionPattern + endPattern);
    specsRegExp = RegExp(specsPattern + endPattern);
    specRegExp = RegExp(specPattern + endPattern);
  }

  MaterialPageRoute generateRoute(RouteSettings settings) {
    print("routing " + settings.name);

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
    } else if (settings.name == "/error") {
      return errorPage(settings);
    }
    // handle regex patterns next, watch for possible ordering sensitivities
    if (specRegExp.hasMatch(settings.name)) {
      return specPage(settings);
    } else if (specsRegExp.hasMatch(settings.name)) {
      return specsPage(settings);
    } else if (versionRegExp.hasMatch(settings.name)) {
      return versionPage(settings);
    } else if (versionsRegExp.hasMatch(settings.name)) {
      return versionsPage(settings);
    } else if (apiRegExp.hasMatch(settings.name)) {
      return apiPage(settings);
    } else if (apisRegExp.hasMatch(settings.name)) {
      return apisPage(settings);
    } else if (projectRegExp.hasMatch(settings.name)) {
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
      return ProjectListPage(
        settings.name,
      );
    },
  );
}

MaterialPageRoute projectPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return ProjectDetailPage(
        name: settings.name,
      );
    },
  );
}

MaterialPageRoute apisPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return ApiListPage(
        settings.name,
      );
    },
  );
}

MaterialPageRoute apiPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return ApiDetailPage(
          name: settings.name,
        );
      });
}

MaterialPageRoute versionsPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return VersionListPage(
          settings.name,
        );
      });
}

MaterialPageRoute versionPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return VersionDetailPage(
          name: settings.name,
        );
      });
}

MaterialPageRoute specsPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return SpecListPage(
        settings.name,
      );
    },
  );
}

MaterialPageRoute specPage(RouteSettings settings) {
  return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return SpecDetailPage(
          name: settings.name,
        );
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
            child: Text("You were sent to a page that doesn't exist.\n" +
                settings.name),
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

MaterialPageRoute errorPage(RouteSettings settings) {
  return MaterialPageRoute(
    settings: settings,
    builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text("${settings.arguments}"),
        ),
      );
    },
  );
}
