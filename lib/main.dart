import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/screens/AvailableMatches.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:provider/provider.dart';

import 'Utils.dart';
import 'models/MatchesModel.dart';
import 'models/UserModel.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ListenableProvider(create: (context) => UserModel()),
      ListenableProvider(create: (context) => MatchesModel(getMatches()))
    ],
    child: new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Container(
          decoration: new BoxDecoration(color: Colors.grey.shade400),
          child: Center(
              child: new LaunchWidget(
                  newPage: new AvailableMatches()))),
      theme: appTheme,
    ),
  ));
}