import 'package:flutter/material.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:shimmer/shimmer.dart';

class Skeletons {
  static var fullWidthText = Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: double.infinity,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static var xlText = Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: 200,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static var xlTextCenter = Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: 200,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static var lText = Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: 120,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static var mText = Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: 80,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static var sText = Container(
    width: 40,
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 40,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
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
    var item = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            )
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

  static Widget imageSkeleton() => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
          width: double.infinity,
          height: 213,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0)
          )
      )
  );
}

class StatsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var r = Row(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 12,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Spacer(),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 12,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
        child: Column(
            children: interleave(
                List<Row>.filled(5, r),
                SizedBox(
                  height: 8,
                ))));
  }
}
