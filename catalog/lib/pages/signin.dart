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
import 'package:google_sign_in/google_sign_in.dart';
import '../authorizations.dart';
import '../service/service.dart';

GoogleSignInAccount currentUser;
bool currentUserIsAuthorized = false;
String currentUserToken = "";

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);

// This runs before the application starts, main() waits for completion.
Future attemptToSignIn() async {
  var completer = new Completer();
  googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
    currentUser = account;
    print("current user changed to $currentUser");
    if (account == null) {
      return;
    }
    currentUserIsAuthorized = authorized_users.contains(account.email);
    account.authentication.then((auth) {
      currentUserToken = auth.idToken;
      StatusService().getStatus().then((status) {
        completer.complete();
      }).catchError((error) {
        print("error calling GetStatus $error");
      });
    });
  });
  googleSignIn.signInSilently();
  return completer.future.timeout(new Duration(milliseconds: 1000),
      onTimeout: () => {print("timeout")});
}

class SignInPage extends StatefulWidget {
  @override
  State createState() => SignInPageState();
}

SignInPageState signInPageState;

class SignInPageState extends State<SignInPage> {
  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {});
    });
    signInPageState = this;
  }

  Future<void> _handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() => googleSignIn.disconnect();

  Widget _buildBody(BuildContext context) {
    if (currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoogleUserCircleAvatar(
                identity: currentUser,
              ),
              Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser.displayName ?? '',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline6),
                      Text(currentUser.email ?? '',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodyText1),
                    ]),
              ),
              RaisedButton(
                child: const Text('Sign out'),
                onPressed: _handleSignOut,
              ),
            ],
          ),
          Container(height: 30),
          if (currentUserIsAuthorized)
            RaisedButton(
              child: const Text('View Projects'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "/projects",
                );
              },
            ),
          if (!currentUserIsAuthorized)
            Column(
              children: [
                Text("Thank you for signing in!"),
                Container(height: 10),
                Text("We're not yet open to the general public."),
                Container(height: 10),
              ],
            ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          //Text(applicationName, style: Theme.of(context).textTheme.headline2),
          Container(height: 20),
          RaisedButton(
            child: const Text('Sign in with Google'),
            onPressed: _handleSignIn,
          ),
          Container(height: 20),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome"),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(context),
      ),
    );
  }
}
