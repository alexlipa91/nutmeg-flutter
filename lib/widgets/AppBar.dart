import 'package:flutter/material.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/screens/Login.dart';
import 'package:nutmeg/screens/UserPage.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

class MainAppBarAsContainer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();
    var userDetails = context.watch<UserChangeNotifier>().getUserDetails();

    return Container(
        color: Palette.primary,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/nutmeg_white.png', width: 106, height: 40),
              if (isLoggedIn)
                InkWell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          backgroundImage: NetworkImage(userDetails.getPhotoUrl()),
                          radius: 25),
                    ),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => new UserPage())))
              else
                InkWell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("LOGIN", style: TextPalette.linkStyleInverted)),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Login())),
              ),
            ],
          ),
        ));
  }
}

// class SecondaryAppBarAsContainer extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         child: Padding(
//       padding: EdgeInsets.all(10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           InkWell(
//               child: Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: Icon(Icons.arrow_back, color: Colors.black)),
//               onTap: () => Navigator.pop(context)),
//           InkWell(
//               child: Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: Icon(Icons.share, color: Colors.black)),
//               onTap: () => print("IMPLEMENT SHARE")),
//         ],
//       ),
//     ));
//   }
// }

class MainAppBar extends StatelessWidget with PreferredSizeWidget {

  @override
  Widget build(BuildContext context) {
    var isLoggedIn = context.watch<UserChangeNotifier>().isLoggedIn();
    var userDetails = context.watch<UserChangeNotifier>().getUserDetails();

    return AppBar(
      centerTitle: false,
      backgroundColor: Palette.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/nutmeg_white.png', height: 24),
            if (isLoggedIn)
              InkWell(
                  child: CircleAvatar(
                      backgroundImage: NetworkImage(userDetails.getPhotoUrl()),
                      radius: 25),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => new UserPage())))
            else
              Center(
                  child: InkWell(
                      child: Text("LOGIN", style: TextPalette.linkStyleInverted),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Login()))))
          ],
        ),
      ),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(0.0);
}

class SecondaryAppBar extends StatelessWidget with PreferredSizeWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_back, color: Colors.black)),
                onTap: () => Navigator.pop(context)),
            InkWell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.share, color: Colors.black)),
                onTap: () => print("IMPLEMENT SHARE")),
          ],
        ),
      )
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.0);
}