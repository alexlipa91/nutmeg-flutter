import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:skeletons/skeletons.dart';

class Skeletons {
  static var fullWidthText = SkeletonLine(
    style: SkeletonLineStyle(
        borderRadius: BorderRadius.circular(20), width: double.infinity, height: 12),
  );

  static var xlText = SkeletonLine(
    style: SkeletonLineStyle(
        borderRadius: BorderRadius.circular(20), width: 200, height: 12),
  );

  static var xlTextCenter = SkeletonLine(
    style: SkeletonLineStyle(
        alignment: AlignmentDirectional.center,
        borderRadius: BorderRadius.circular(20), width: 200, height: 12),
  );

  static var lText = SkeletonLine(
    style: SkeletonLineStyle(
        borderRadius: BorderRadius.circular(20), width: 120, height: 12),
  );

  static var mText = SkeletonLine(
    style: SkeletonLineStyle(
        borderRadius: BorderRadius.circular(20), width: 80, height: 12),
  );

  static var sText = Container(
    width: 40,
    child: SkeletonLine(
      style: SkeletonLineStyle(
          alignment: AlignmentDirectional.center,
          borderRadius: BorderRadius.circular(20), width: 40, height: 12),
    ),
  );
}

class ListOfMatchesSkeleton extends StatelessWidget {

  final int repeatFor;
  final bool withContainer;

  const ListOfMatchesSkeleton({Key? key, required this.repeatFor}) :
        withContainer = true,
        super(key: key);

  const ListOfMatchesSkeleton.withoutContainer({Key? key, required this.repeatFor}) :
        withContainer = false,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var item = SkeletonItem(
      child: Row(
        children: [
          SkeletonAvatar(
            style: SkeletonAvatarStyle(
              borderRadius: BorderRadius.circular(20),
              width: 60,
              height: 78,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeletons.xlText,
              SizedBox(
                height: 12,
              ),
              Skeletons.lText,
              SizedBox(
                height: 12,
              ),
              Skeletons.mText
            ],
          )
        ],
      ),
    );

    return Column(
        children: interleave(
            List<Widget>.filled(repeatFor,
                withContainer ?
                InfoContainer(
                  child: item
                ) : item
            ),
            SizedBox(height: 24,)
        )
    );
  }
}

class SkeletonMatchDetails {

  static Widget skeletonRepeatedElement() => Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Skeletons.fullWidthText,
        Column(children: List<Widget>.filled(3,
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(children: [
                Skeletons.sText,
                SizedBox(width: 12),
                Expanded(
                  child: Skeletons.fullWidthText
                ),
              ],),
            )))
      ])
  );

  static Widget imageSkeleton() => SkeletonAvatar(
      style: SkeletonAvatarStyle(
          width: double.infinity,
          height: 213,
          borderRadius: BorderRadius.circular(10.0)));
}

class StatsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var r = Row(
      children: [
        SkeletonAvatar(
          style: SkeletonAvatarStyle(
              shape: BoxShape.circle, width: 32, height: 32),
        ),
        SizedBox(width: 8),
        SkeletonLine(
            style: SkeletonLineStyle(
          height: 12,
          width: 120,
          borderRadius: BorderRadius.circular(8),
        )),
        Spacer(),
        SkeletonLine(
            style: SkeletonLineStyle(
          height: 12,
          width: 40,
          borderRadius: BorderRadius.circular(8),
        )),
      ],
    );

    return SkeletonItem(
        child: Column(
            children: interleave(
                List<Row>.filled(5, r),
                SizedBox(
                  height: 8,
                ))));
  }
}
