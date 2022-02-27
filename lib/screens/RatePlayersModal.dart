import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:nutmeg/controller/MatchesController.dart';
import 'package:nutmeg/controller/UserController.dart';
import 'package:nutmeg/model/ChangeNotifiers.dart';
import 'package:nutmeg/model/Model.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/ButtonsWithLoader.dart';
import 'package:provider/provider.dart';

import '../controller/CloudFunctionsUtils.dart';
import '../widgets/Avatar.dart';
import '../widgets/PlayerBottomModal.dart';


class RateButton extends StatelessWidget {
  final Match match;

  const RateButton({Key key, this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericButtonWithLoader("RATE PLAYERS",
            (BuildContext context) async {

          // await UserController.refreshUsersToRateInMatch(match.documentId,
          //     context.read<UserState>().getUserDetails().documentId,
          //     context.read<UserState>());
          //     print(match.documentId);
          // print(context.read<UserState>().getUsersStillToRate(match.documentId));

          List<UserDetails> users = (await UserController.getUsersToRateInMatch(match.documentId,
              context.read<UserState>().getUserDetails().documentId,
              // userState
          )).where((element) => element != null).toList();

          print("num users " + users.length.toString());

          await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) =>
                  RatingPlayerBottomModal(
                    userDetails: users,
                    matchId: match.documentId,
                  ));
          context.read<GenericButtonWithLoaderState>().change(false);
        },
        Primary());
  }
}

class RatingPlayerBottomModal extends StatefulWidget {
  final List<UserDetails> userDetails;
  final String matchId;

  const RatingPlayerBottomModal({Key key, this.userDetails, this.matchId}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      RatingPlayerBottomModalState(userDetails, matchId);
}

class RatingPlayerBottomModalState extends State<RatingPlayerBottomModal> {
  final List<UserDetails> usersRatedDetails;
  final String matchId;

  int index = 0;
  double score = 3;

  RatingPlayerBottomModalState(this.usersRatedDetails, this.matchId);

  @override
  Widget build(BuildContext context) {
    print("have " + usersRatedDetails.length.toString() + " to rate");
    return Stack(
        alignment: AlignmentDirectional.bottomStart,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Palette.white,
            child: Column(
              children: [
                SizedBox(height: 70),
                Text(PlayerBottomModal.getDisplayName(usersRatedDetails[index]),
                    style: TextPalette.h2),
                SizedBox(height: 20),
                RatingBar.builder(
                  initialRating: 3,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      score = rating;
                    });
                  },
                ),
                GenericButtonWithLoader(
                    (index == usersRatedDetails.length - 1) ? "DONE" : "NEXT",
                        (BuildContext context) async {
                      context.read<GenericButtonWithLoaderState>().change(true);

                      try {
                        await CloudFunctionsUtils.callFunction("add_rating",
                            {"user_id": context.read<UserState>().getUserDetails().documentId,
                              "user_rated_id": usersRatedDetails[index].documentId,
                              "match_id": matchId, "score": score});
                      } catch (e, s) {
                        print("Failed to add rating: " + e.toString());
                        print(s);
                      }

                      if (index == usersRatedDetails.length - 1) {
                        print("finished list");
                        await MatchesController.refresh(
                            context.read<MatchesState>(),
                            context.read<UserState>(), matchId);

                        Navigator.pop(context);
                        print("done");
                        return;
                      }
                      setState(() {
                        index = index + 1;
                      });

                      context.read<GenericButtonWithLoaderState>().change(false);
                    }, Primary())
              ],
            ),
          ),
          Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: UserAvatarWithBorder(usersRatedDetails[index])),
        ]);
  }
}

