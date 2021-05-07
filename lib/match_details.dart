import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'matches_available.dart';
import 'model.dart';
import 'package:maps_launcher/maps_launcher.dart';


class MatchDetails extends StatelessWidget {
  Match m;

  MatchDetails(Match m) {
    this.m = m;
  }

  var font = "Lato";
  var faceIcon = new Icon(const IconData(0xe71a, fontFamily: 'MaterialIcons'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Utils.getAppBar("Match details", context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15),
          Text(m.sport,
              style: GoogleFonts.getFont(font,
                  textStyle:
                      TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold))),
          SizedBox(height: 15),
          Text("8 left",
              style: GoogleFonts.getFont(font,
                  textStyle:
                      TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold))),
          SizedBox(height: 15),
          TextButton(
            child: Text('Join',
                style: GoogleFonts.getFont(font,
                    textStyle: TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold))),
            onPressed: () {
              print('Pressed');
            },
            style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.red)))),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.map),
                iconSize: 48,
                onPressed: () {
                  print("map pressed");
                  MapsLauncher.launchCoordinates(m.sportCenter.lat, m.sportCenter.long, m.sportCenter.name);
                },
              ),
              Text(m.sportCenter.name,
                  style: GoogleFonts.getFont(font,
                      textStyle: TextStyle(fontSize: 18.0)))
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.watch, size: 48),
              Text(m.dateTime.hour.toString() + ":" + m.dateTime.minute.toString(),
                  style: GoogleFonts.getFont(font,
                      textStyle: TextStyle(fontSize: 18.0)))
            ],
          ),
          SizedBox(height: 15),
          Row(children: [
            Icon(Icons.monetization_on, size: 48),
            Text(m.price.toString() + " euro",
                style: GoogleFonts.getFont(font,
                    textStyle: TextStyle(fontSize: 18.0)))
          ]),
          Spacer(),
          Align(
              alignment: Alignment.bottomCenter,
              child: Card(
                  child: Column(
                children: [
                  SizedBox(height: 15),
                  Text("2/10 going",
                      style: GoogleFonts.getFont(font,
                          textStyle: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold))),
                  SizedBox(height: 15),
                  Row(children: [faceIcon, faceIcon, faceIcon, faceIcon]),
                  SizedBox(height: 15),
                ],
              )))
        ],
      ),
    );
  }
}
