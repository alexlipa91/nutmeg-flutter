import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:nutmeg/utils/UiUtils.dart';


var badgeIt = (child, content, position) => Badge(
    toAnimate: false,
    badgeContent: content,
    child: child,
    badgeColor: Colors.transparent,
    borderSide: BorderSide.none,
    elevation: 0,
    position: position);

class TestBadge extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
      ),
      child: CircleAvatar(
          child: Center(
              child: Text("T",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                      color: Palette.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500))),
          radius: 14,
          backgroundColor: Palette.destructive),
    );
  }
}