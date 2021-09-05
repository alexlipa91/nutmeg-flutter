import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/admin/Matches.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/AppBar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:nutmeg/widgets/SplashScreen.dart';
import 'package:provider/provider.dart';

class UserPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    print("building user page");
    var userDetails = context.watch<UserChangeNotifier>().getUserDetails();

    if (userDetails == null) { // add this to avoid null pointer exceptions at logout
      return Container();
    }

    return Scaffold(
      appBar: UserPageAppBar(),
      body: SafeArea(
        child: Container(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("Account", style: TextPalette.h1Default)),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: InfoContainer(
                  child: Row(
                children: [
                  CircleAvatar(
                      backgroundImage: NetworkImage(userDetails.image),
                      radius: 24,
                      backgroundColor: Palette.white),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userDetails.name, style: TextPalette.h2),
                        SizedBox(height: 10),
                        Text(userDetails.email,
                            style: TextPalette.bodyText)
                      ],
                    ),
                  )
                ],
              )),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoContainer(
                    child: Column(
                      children: [
                        Text(userDetails.getCreditsAvailable(),
                            style: TextPalette.h2),
                        SizedBox(height: 20),
                        Text("Available Credits", style: TextPalette.h3)
                      ],
                    ),
                  ),
                  InfoContainer(
                      child: Column(
                    children: [
                      Text(
                          context
                                  .watch<MatchesChangeNotifier>()
                                  .numPlayedByUser(userDetails.getUid())
                                  .toString() +
                              " games played",
                          style: TextPalette.h2),
                      SizedBox(height: 20),
                      Text("Games Played", style: TextPalette.h3)
                    ],
                  ))
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [Expanded(
                  child: RoundedButton("LOGOUT", () async {
                    print("pressed logout");
                    await Navigator.pushReplacement(context,
                        MaterialPageRoute(
                            builder: (context) => SplashScreen(context.read<UserChangeNotifier>().logout())));
                    Navigator.of(context).pop();
                  }),
                )],
              ),
            ),
            if (userDetails.isAdmin)
              Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [Expanded(
                  child: RoundedButton("ADMIN AREA", () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AdminAvailableMatches()));
                    await context.read<MatchesChangeNotifier>().refresh();
                  }),
                )],
              ),
            )
          ]),
        )),
      ),
    );
  }
}
