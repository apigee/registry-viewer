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
import 'package:flutter/material.dart';
import 'package:registry/registry.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../authorizations.dart';
import '../service/service.dart';
import '../components/home.dart';
import '../application.dart';

GoogleSignInAccount? currentUser;
bool currentUserIsAuthorized = false;

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);

// This runs before the application starts, main() waits for completion.
Future attemptToSignIn() async {
  var completer = Completer();
  googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
    currentUser = account;
    debugPrint("current user changed to $currentUser");
    if (account == null) {
      return;
    }
    currentUserIsAuthorized = authorized_users.contains(account.email);
    if (!currentUserIsAuthorized) {
      currentUserIsAuthorized =
          authorized_domains.contains(account.email.split("@").last);
    }
    currentUserIsAuthorized = true;
    account.authentication.then((auth) {
      setRegistryUserToken(auth.idToken!);
      StatusService().getStatus()!.then((status) {
        completer.complete();
      }).catchError((error) {
        debugPrint("error calling GetStatus $error");
      });
    });
  });
  googleSignIn.signInSilently();
  return completer.future
      .timeout(const Duration(milliseconds: 1000), onTimeout: () => {});
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {});
    });
  }

  Future<void> _handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      debugPrint("$error");
    }
  }

  Future<void> _handleSignOut() => googleSignIn.disconnect();

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text((currentUser == null) ? "" : applicationName),
      actions: <Widget>[
        if (currentUser != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentUser!.displayName ?? '',
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .apply(color: Colors.white)),
                  Text(currentUser?.email ?? '',
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .apply(color: Colors.white)),
                ]),
          ),
        if (currentUser != null)
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('Sign out'),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!currentUserIsAuthorized)
            Column(
              children: [
                const Text("Thank you for signing in!"),
                Container(height: 10),
                const Text("We're not yet open to the public."),
                Container(height: 10),
              ],
            ),
          if (currentUserIsAuthorized) Expanded(child: Home()),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(height: 20),
          ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('Sign in with Google'),
          ),
          Container(height: 20),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context) as PreferredSizeWidget?,
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Container(color: Colors.grey[400], child: _buildBody(context)),
      ),
    );
  }
}
