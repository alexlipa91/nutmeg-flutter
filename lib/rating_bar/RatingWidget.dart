import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/RatingPlayersState.dart';

typedef void RatingChangeCallback(double rating);

class RatingBar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return SmoothStarRating(
        allowHalfRating: false,
        starCount: 5,
        rating: context.watch<RatingPlayersState>().currentScore,
        size: 40.0,
        isReadOnly: false,
        color: Colors.amber,
        defaultIconData: Icons.star,
        borderColor: Colors.grey,
        spacing:0.0
    );
  }

}

class SmoothStarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback onRated;
  final Color color;
  final Color borderColor;
  final double size;
  final bool allowHalfRating;
  final IconData filledIconData;
  final IconData halfFilledIconData;
  final IconData
  defaultIconData; //this is needed only when having fullRatedIconData && halfRatedIconData
  final double spacing;
  final bool isReadOnly;
  SmoothStarRating({
    this.starCount = 5,
    this.isReadOnly = false,
    this.spacing = 0.0,
    this.rating = 0.0,
    this.defaultIconData = Icons.star_border,
    this.onRated,
    this.color,
    this.borderColor,
    this.size = 25,
    this.filledIconData = Icons.star,
    this.halfFilledIconData = Icons.star_half,
    this.allowHalfRating = true,
  }) {
    assert(this.rating != null);
  }
  @override
  _SmoothStarRatingState createState() => _SmoothStarRatingState();
}

class _SmoothStarRatingState extends State<SmoothStarRating> {
  final double halfStarThreshold =
  0.53; //half star value starts from this number

  //tracks for user tapping on this widget
  bool isWidgetTapped = false;
  Timer debounceTimer;

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
                widget.starCount, (index) => buildStar(context, index))),
        ],
      ),
    );
  }

  Widget buildStar(BuildContext context, int index) {
    var rat = context.watch<RatingPlayersState>().getCurrentScore();

    Icon icon;
    if (index >= rat) {
      icon = Icon(
        widget.defaultIconData,
        color: widget.borderColor ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    } else if (index >
        rat -
            (widget.allowHalfRating ? halfStarThreshold : 1.0) &&
        index < rat) {
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
      onExit: (event) {
        if (widget.onRated != null && !isWidgetTapped) {
          //reset to zero only if rating is not set by user
          context.read<RatingPlayersState>().setCurrentScore(0);
        }
      },
      onEnter: (event) {
        isWidgetTapped = false; //reset
      },
      onHover: (event) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(event.position);
        var i = _pos.dx / widget.size;
        var newRating =
        widget.allowHalfRating ? i : i.round().toDouble();
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        context.read<RatingPlayersState>().setCurrentScore(newRating);
      },
      child: GestureDetector(
        onTapDown: (detail) {
          isWidgetTapped = true;

          RenderBox box = context.findRenderObject();
          var _pos = box.globalToLocal(detail.globalPosition);
          var i = ((_pos.dx - widget.spacing) / widget.size);
          var newRating =
          widget.allowHalfRating ? i : i.round().toDouble();
          if (newRating > widget.starCount) {
            newRating = widget.starCount.toDouble();
          }
          if (newRating < 0) {
            newRating = 0.0;
          }
          context.read<RatingPlayersState>().setCurrentScore(newRating);
          if (widget.onRated != null) {
            widget.onRated(normalizeRating(newRating));
          }
        },
        onHorizontalDragUpdate: (dragDetails) {
          isWidgetTapped = true;

          RenderBox box = context.findRenderObject();
          var _pos = box.globalToLocal(dragDetails.globalPosition);
          var i = _pos.dx / widget.size;
          var newRating =
          widget.allowHalfRating ? i : i.round().toDouble();
          if (newRating > widget.starCount) {
            newRating = widget.starCount.toDouble();
          }
          if (newRating < 0) {
            newRating = 0.0;
          }
          context.read<RatingPlayersState>().setCurrentScore(newRating);
          debounceTimer?.cancel();
          debounceTimer = Timer(Duration(milliseconds: 100), () {
            if (widget.onRated != null) {
              var n = normalizeRating(newRating);
              widget.onRated(n);
            }
          });
        },
        child: icon,
      ),
    )
        : GestureDetector(
      onTapDown: (detail) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(detail.globalPosition);
        var i = ((_pos.dx - widget.spacing) / widget.size);
        var newRating =
        widget.allowHalfRating ? i : i.round().toDouble();
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        newRating = normalizeRating(newRating);
        context.read<RatingPlayersState>().setCurrentScore(newRating);
      },
      onTapUp: (e) {
        if (widget.onRated != null) widget.onRated(
            context.read<RatingPlayersState>().currentScore);
      },
      onHorizontalDragUpdate: (dragDetails) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(dragDetails.globalPosition);
        var i = _pos.dx / widget.size;
        var newRating =
        widget.allowHalfRating ? i : i.round().toDouble();
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        context.read<RatingPlayersState>().setCurrentScore(newRating);
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 100), () {
          if (widget.onRated != null) {
            context.read<RatingPlayersState>().setCurrentScore(newRating);
            widget.onRated(context.read<RatingPlayersState>().getCurrentScore());
          }
        });
      },
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