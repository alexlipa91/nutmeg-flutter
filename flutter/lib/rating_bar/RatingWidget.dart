import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:provider/provider.dart';

import '../state/UserRatings.dart';

typedef void RatingChangeCallback(double rating);

class RatingBar extends StatelessWidget {
  final String userId;

  RatingBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return SmoothStarRating(
        userId: userId,
        allowHalfRating: false,
        starCount: 5,
        rating: context.watch<UserRatings>().getRating(userId).toDouble(),
        size: 25.0,
        isReadOnly: false,
        color: Palette.accent,
        defaultIconData: Icons.star_border,
        borderColor: Palette.greyLight,
        spacing: 8.0, onRated: (double rating) {  },
    );
  }

}

class SmoothStarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback onRated;
  final Color? color;
  final Color? borderColor;
  final double size;
  final bool allowHalfRating;
  final IconData filledIconData;
  final IconData halfFilledIconData;
  final IconData
  defaultIconData; //this is needed only when having fullRatedIconData && halfRatedIconData
  final double spacing;
  final bool isReadOnly;

  final String userId;

  SmoothStarRating({
    this.starCount = 5,
    this.isReadOnly = false,
    this.spacing = 0.0,
    this.rating = 0,
    this.defaultIconData = Icons.star_border,
    required this.onRated,
    required this.color,
    required this.borderColor,
    this.size = 25,
    this.filledIconData = Icons.star,
    this.halfFilledIconData = Icons.star_half,
    this.allowHalfRating = true,
    required this.userId,
  });

  @override
  _SmoothStarRatingState createState() => _SmoothStarRatingState();
}

class _SmoothStarRatingState extends State<SmoothStarRating> {
  final double halfStarThreshold = 0.53; //half star value starts from this number

  //tracks for user tapping on this widget
  bool isWidgetTapped = false;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    debounceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            spacing: widget.spacing,
            children: List.generate(
                widget.starCount, (index) => buildStar(context, index, widget.rating)),
          ),
        ],
      ),
    );
  }

  Widget buildStar(BuildContext context, int index, double rating) {

    Icon icon;
    if (index >= rating) {
      icon = Icon(
        widget.defaultIconData,
        color: widget.borderColor ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    } else if (index >
        rating -
            (widget.allowHalfRating ? halfStarThreshold : 1.0) &&
        index < rating) {
      icon = Icon(
        widget.halfFilledIconData,
        color: widget.color ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    } else {
      icon = Icon(
        widget.filledIconData,
        color: widget.color ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    }
    final Widget star = widget.isReadOnly
        ? icon
        : kIsWeb
        ? MouseRegion(
      onEnter: (event) {
        isWidgetTapped = false; //reset
      },
      // onHover: (event) {
      //   RenderBox box = context.findRenderObject();
      //   var _pos = box.globalToLocal(event.position);
      //   var i = _pos.dx / widget.size;
      //   var newRating =
      //   widget.allowHalfRating ? i : i.round().toDouble();
      //   if (newRating > widget.starCount) {
      //     newRating = widget.starCount.toDouble();
      //   }
      //   if (newRating < 0) {
      //     newRating = 0.0;
      //   }
      //   context.read<RatingPlayersState>().setCurrentScore(newRating);
      // },
      child: GestureDetector(
          onTapDown: (detail) {
            RenderBox box = context.findRenderObject() as RenderBox;
            var _pos = box.globalToLocal(detail.globalPosition);
            var i = ((_pos.dx - widget.spacing) / widget.size);
            // var newRating =
            // widget.allowHalfRating ? i : i.round().toDouble();
            var newRating = i.ceil().toDouble();  // just take the ceil
            if (newRating > widget.starCount) {
              newRating = widget.starCount.toDouble();
            }
            if (newRating < 0) {
              newRating = 0.0;
            }
            // newRating = normalizeRating(newRating);
            context.read<UserRatings>().setRating(widget.userId, newRating.toInt()  );
          },
          // onTapUp: (e) {
          //   widget.onRated(
          //       context.read<RatingPlayersState>().currentScore);
          // },
          // onHorizontalDragUpdate: (dragDetails) {
          //   RenderBox box = context.findRenderObject();
          //   var _pos = box.globalToLocal(dragDetails.globalPosition);
          //   var i = _pos.dx / widget.size;
          //   var newRating =
          //   widget.allowHalfRating ? i : i.round().toDouble();
          //   if (newRating > widget.starCount) {
          //     newRating = widget.starCount.toDouble();
          //   }
          //   if (newRating < 0) {
          //     newRating = 0.0;
          //   }
          //   context.read<RatingPlayersState>().setCurrentScore(newRating);
          //   debounceTimer?.cancel();
          //   debounceTimer = Timer(Duration(milliseconds: 100), () {
          //     if (widget.onRated != null) {
          //       context.read<RatingPlayersState>().setCurrentScore(newRating);
          //       widget.onRated(context.read<RatingPlayersState>().getCurrentScore());
          //     }
          //   });
          // },
          child: icon,
        ),
      )
        : GestureDetector(
      onTapDown: (detail) {
        RenderBox box = context.findRenderObject() as RenderBox;
        var _pos = box.globalToLocal(detail.globalPosition);
        var i = ((_pos.dx - widget.spacing) / widget.size);
        // var newRating =
        // widget.allowHalfRating ? i : i.round().toDouble();
        var newRating = i.ceil().toDouble();  // just take the ceil
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        // newRating = normalizeRating(newRating);
        context.read<UserRatings>().setRating(widget.userId, newRating.toInt());
      },
      onTapUp: (e) {
        widget.onRated(context.read<UserRatings>().getRating(widget.userId).toDouble());
      },
      // onHorizontalDragUpdate: (dragDetails) {
      //   RenderBox box = context.findRenderObject();
      //   var _pos = box.globalToLocal(dragDetails.globalPosition);
      //   var i = _pos.dx / widget.size;
      //   var newRating =
      //   widget.allowHalfRating ? i : i.round().toDouble();
      //   if (newRating > widget.starCount) {
      //     newRating = widget.starCount.toDouble();
      //   }
      //   if (newRating < 0) {
      //     newRating = 0.0;
      //   }
      //   context.read<RatingPlayersState>().setCurrentScore(newRating);
      //   debounceTimer?.cancel();
      //   debounceTimer = Timer(Duration(milliseconds: 100), () {
      //     if (widget.onRated != null) {
      //       context.read<RatingPlayersState>().setCurrentScore(newRating);
      //       widget.onRated(context.read<RatingPlayersState>().getCurrentScore());
      //     }
      //   });
      // },
      child: icon,
    );

    return star;
  }

  double normalizeRating(double newRating) {
    var k = newRating - newRating.floor();
    if (k != 0) {
      //half stars
      if (k >= halfStarThreshold) {
        newRating = newRating.floor() + 1.0;
      } else {
        newRating = newRating.floor() + 0.5;
      }
    }
    return newRating;
  }
}