import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:provider/provider.dart';

import '../state/LoginStatusChangeNotifier.dart';

class EnterDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Firebase.initializeApp();
    var images = Row(children: [
      Expanded(
          child: SingleChildScrollView(
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
            ]),
          ))
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => LoginStatusChangeNotifier()),
      ],
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(),
            actions: [
              Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: InkWell(
                    child: Icon(Icons.close),
                    onTap: () => Get.back(),
                  ))
            ],
          ),
          body: Stack(children: [
            Container(
                constraints: BoxConstraints.expand(),
                decoration: new BoxDecoration(color: Palette.primary)),
            images,
            EnterNameArea()
          ])),
    );
  }
}

class EnterNameArea extends StatelessWidget {

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/nutmeg_white.png', width: 106, height: 40),
          SizedBox(height: 30),
          InfoContainer(
              child: Column(
            children: [
              Text("Complete your profile", style: TextPalette.h2),
              SizedBox(height: 16),
              Text(
                  "To complete your profile please enter your display name below",
                  style: TextPalette.bodyText),
              SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your name *',
                ),
                controller: _controller,
              ),
              SizedBox(height: 16),
              GenericButtonWithLoader("CREATE ACCOUNT", (BuildContext context) async {
                Get.back(result: _controller.value.text);
              }, Primary())
            ],
          ))
        ],
      ),
    );
  }
}
