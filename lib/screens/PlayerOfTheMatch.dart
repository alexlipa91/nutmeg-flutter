import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class PlayerOfTheMatch extends StatelessWidget {
  final GlobalKey previewContainer = new GlobalKey();
  final screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    var images = Row(children: [
      Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Align(
                alignment: Alignment.topLeft,
                child: SvgPicture.asset('assets/launch/blob_top_left.svg')),
            SvgPicture.asset('assets/launch/blob_middle_middle.svg',
                width: MediaQuery.of(context).size.width),
            Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset('assets/launch/blob_bottom_right.svg'))
          ]))
    ]);

    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
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
                  onTap: () => GoRouter.of(context).pop(),
                ))
          ],
        ),
        body: Stack(children: [
          Container(
              constraints: BoxConstraints.expand(),
              decoration: new BoxDecoration(color: Palette.primary)),
          images,
          MainArea(userId: uid!, screenshotController: screenshotController)
        ]),
      ),
    );
  }
}

class MainArea extends StatefulWidget {
  final String userId;
  final ScreenshotController screenshotController;

  const MainArea({Key? key, required this.userId, required this.screenshotController}) : super(key: key);

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
    var userDetails = (widget.userId == null)
        ? userState.getLoggedUserDetails()
        : userState.getUserDetail(widget.userId);

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
                                  GoRouter.of(context).pop(),
                          PrimaryInverted()),
                      ShareButton(() async {
                        var appDir = await getApplicationDocumentsDirectory();
                        var filePath = await widget.screenshotController
                            .captureAndSave(appDir.path);
                        Share.shareFiles([filePath!]);
                      }, Palette.white)
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
