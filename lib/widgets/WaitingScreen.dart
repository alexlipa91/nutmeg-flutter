import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:shimmer/shimmer.dart';

class WaitingScreenLight extends StatelessWidget {
  final Function toRun;

  const WaitingScreenLight({Key key, this.toRun}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var future = () async {
      await toRun();
      Navigator.pop(context);
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Palette.light,
        ),
        child: FutureBuilder<void>(
          future: future(),
          builder: (context, snapshot) => (snapshot.hasError)
              // fixme user readable
              ? Text(snapshot.error.toString(), style: TextPalette.linkStyle)
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Palette.primary)),
                    ])),
        ),
      ),
    );
  }
}

class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;

  const CustomShimmer({Key key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)))));
  }
}
