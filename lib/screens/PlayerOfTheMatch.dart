import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';


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
          automaticallyImplyLeading: false,
          leadingWidth: 0,
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
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(48, context.read<UserState>().getLoggedUserDetails()),
              SizedBox(height: 24),
              Text("Player of the Match",
                  textAlign: TextAlign.center,
                  style: TextPalette.h1Inverted),
              SizedBox(height: 4),
              Text("Congratulations " + context.read<UserState>().getLoggedUserDetails().name + "! You won the Player of the Match award",
                  textAlign: TextAlign.center,
                  style: TextPalette.getBodyText(Palette.white)),
              SizedBox(height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Image.asset('assets/potm_badge.png', height: 40,),
                SizedBox(width: 8),
                Text("+1", style: TextPalette.getH2(Palette.white))
              ]),
              SizedBox(height: 24),
              GenericButtonWithLoader("SEE MATCH STATS", (BuildContext context) async {
                Get.back();
              }, PrimaryInverted())
            ],
          ),
        ),
      ),
    );
  }
}
