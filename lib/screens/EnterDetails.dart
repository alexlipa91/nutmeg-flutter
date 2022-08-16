import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
            actions: [],
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

class EnterNameArea extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => EnterNameAreaState();
}

class EnterNameAreaState extends State<EnterNameArea> {

  final TextEditingController _controller = TextEditingController();

  bool isValid = true;

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
                  errorText: (isValid) ? null : "Name not valid",
                ),
                controller: _controller,
                onChanged: (String v) {
                  bool valid = v != null && v != "";
                  setState(() {
                    isValid = valid;
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [Expanded(
                  child: GenericButtonWithLoader("CREATE ACCOUNT", (BuildContext context) async {
                    if (_controller.value.text == "") {
                      setState(() {
                        isValid = false;
                      });
                    }
                    if (isValid) {
                      Navigator.of(context).pop(_controller.value.text);
                    }
                  }, Primary()),
                )],
              )
            ],
          ))
        ],
      ),
    );
  }
}
