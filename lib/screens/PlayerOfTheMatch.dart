import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/screens/Launch.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';


class PlayerOfTheMatch extends StatelessWidget {
  final GlobalKey previewContainer = new GlobalKey();

  final String? userId;

  PlayerOfTheMatch({Key? key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 20),
                child: InkWell(
                  child: Icon(Icons.close),
                  onTap: () => Navigator.of(context).pop(),
                ))
          ],
        ),
        body: Stack(children: [
          Container(
              constraints: BoxConstraints.expand(),
              decoration: new BoxDecoration(color: Palette.primary)),
          LaunchWidgetState.getBackgroundImages(context),
          MainArea(userId: userId ?? context.read<UserState>().currentUserId!)
        ]),
      );
  }
}

class MainArea extends StatefulWidget {
  final String userId;

  const MainArea({Key? key, required this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MainAreaState();
}

class MainAreaState extends State<MainArea> {
  final _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserState>();
    var userDetails = userState.getUserDetail(widget.userId);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.directional,
                blastDirection: pi / 2,
                emissionFrequency: 0.3,
                // how often it should emit
                numberOfParticles: 5,
                // number of particles to emit
                gravity: 1,
                // gravity - or fall speed
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.red],
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      UserAvatar(48, userDetails!),
                      SizedBox(height: 24),
                      Text("Player of the Match",
                          textAlign: TextAlign.center,
                          style: TextPalette.h1Inverted),
                      SizedBox(height: 4),
                      Text(
                          "Congratulations " +
                              (userDetails.name)! +
                              "! You won the Player of the Match award",
                          textAlign: TextAlign.center,
                          style: TextPalette.getBodyText(Palette.white)),
                      SizedBox(height: 24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/potm_badge.png',
                              height: 40,
                            ),
                            SizedBox(width: 8),
                            Text("+1", style: TextPalette.getH2(Palette.white))
                          ]),
                      SizedBox(height: 24),
                      GenericButtonWithLoader("SEE MATCH STATS",
                              (BuildContext context) async =>
                                  Navigator.of(context).pop(),
                          PrimaryInverted()),
                    ],
                  ),
                ),
              ),
            ],
          )
      ),
    );
  }
}
