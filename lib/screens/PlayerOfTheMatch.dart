import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/state/MatchesState.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/Buttons.dart';
import 'package:provider/provider.dart';
import 'package:share_files_and_screenshot_widgets/share_files_and_screenshot_widgets.dart';


class PlayerOfTheMatch extends StatelessWidget {

  GlobalKey previewContainer = new GlobalKey();

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

    return RepaintBoundary(
      key: previewContainer,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leadingWidth: 0,
          // leading: Padding(
          //   padding: EdgeInsets.only(left: 20),
          //   child: ShareButton(() async {
          //       print("share");
          //       ShareFilesAndScreenshotWidgets().shareScreenshot(
          //           previewContainer,
          //           MediaQuery.of(context).size.width.toInt() * 2,
          //           "PlayerOfTheMatch",
          //           "Nutmeg-PlayerOfTheMatch.png",
          //           "image/png",
          //           text: "");
          //     }, Palette.white),
          // ),
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 20),
                child: InkWell(
                  child: Icon(Icons.close),
                  onTap: () => Get.back(),
                )
            )
          ],
        ),
        body: Stack(children: [
          Container(
            constraints: BoxConstraints.expand(),
            decoration: new BoxDecoration(color: Palette.primary)),
          images,
          MainArea(matchId: Get.parameters["matchId"])
        ])
      ),
    );
  }
}

class MainArea extends StatelessWidget {

  final String matchId;

  const MainArea({Key key, this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var score = context.read<MatchesState>().getMatch(matchId).manOfTheMatchScore;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/potm.png'),
            SizedBox(height: 30),
            Text("PLAYER\nOF THE MATCH", textAlign: TextAlign.center,
                style: GoogleFonts.roboto(color: Palette.white, fontSize: 30, fontWeight: FontWeight.w900)),
            SizedBox(height: 30),
            UserAvatar(50, context.read<UserState>().getLoggedUserDetails()),
            SizedBox(height: 30),
            Text("Congratulations " + context.read<UserState>().getLoggedUserDetails().name + "!",
                style: GoogleFonts.roboto(color: Palette.white, fontSize: 24, fontWeight: FontWeight.w900)),
            SizedBox(height: 10),
            Text("You won player of the match", style: GoogleFonts.roboto(color: Palette.white, fontSize: 20, fontWeight: FontWeight.w500)),
            SizedBox(height: 30),
            Text(score.toStringAsFixed(1), style: GoogleFonts.roboto(color: Palette.white, fontSize: 44, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
