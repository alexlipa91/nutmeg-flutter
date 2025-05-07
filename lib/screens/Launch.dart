import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nutmeg/controller/LaunchController.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/utils/CrashlyticsLogger.dart';

final logger = CrashlyticsLogger('Launch');

class LaunchWidget extends StatefulWidget {
  final String? from;
  final Map<String, String>? queryParams;

  const LaunchWidget({Key? key, this.from, this.queryParams}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LaunchWidgetState();
}

class LaunchWidgetState extends State<LaunchWidget> {
  @override
  void initState() {
    super.initState();
    LaunchController.loadData(context, widget.from)
        .catchError((e, s) => logger.severe("Error loading data", e, s));
  }

  void initDynamicLinks() {
    Future<Null> Function(PendingDynamicLinkData? dynamicLink) onSuccess =
        (PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        LaunchController.handleLink(deepLink);
      }
    };

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      onSuccess(dynamicLinkData);
    }).onError((error) {
      logger.severe("Error on dynamic link", error);
    });
  }

  @override
  Widget build(BuildContext context) {
    var mainWidgets =
        Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/loading.gif", width: 100),
              SizedBox(height: 30),
              Image.asset("assets/nutmeg_white.png", width: 116, height: 46),
            ],
          )
        ],
      ))
    ]);

    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              color: Palette.primary,
            ),
            child:
                Stack(children: [getBackgroundImages(context), mainWidgets])));
  }

  static Widget getBackgroundImages(BuildContext context) => Row(children: [
        Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: SvgPicture.asset('assets/launch/blob_top_left.svg')),
              Expanded(
                child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: SvgPicture.asset(
                      'assets/launch/blob_middle_middle.svg',
                      fit: BoxFit.fill,
                    )),
              ),
              Align(
                  alignment: Alignment.bottomRight,
                  child:
                      SvgPicture.asset('assets/launch/blob_bottom_right.svg'))
            ]))
      ]);
}
