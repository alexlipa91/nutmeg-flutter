import 'package:flutter/material.dart';
import 'package:nutmeg/models/MatchesModel.dart';
import 'package:nutmeg/models/UserModel.dart';
import 'package:provider/provider.dart';


class Payment extends StatelessWidget {

  final int matchId;

  const Payment({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: new BoxDecoration(color: Colors.grey.shade400),
      child: new TextButton(onPressed: () {
        context.read<MatchesModel>().joinMatch(
            context.read<UserModel>().user.uid, matchId);

        Navigator.pop(context);
      }, child: Text("pay")),
    );
  }
}