import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class SkeletonMatchDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeletonItem(
        child: Column(
      children: [
        SkeletonAvatar(
          style: SkeletonAvatarStyle(
            borderRadius: BorderRadius.circular(8),
            width: double.infinity,
            minHeight: (MediaQuery.of(context).size.height / 4) - 1,
            maxHeight: MediaQuery.of(context).size.height / 4,
          ),
        ),
        SizedBox(height: 12),
        SkeletonParagraph(
          style: SkeletonParagraphStyle(
              lines: 3,
              spacing: 12,
              lineStyle: SkeletonLineStyle(
                borderRadius: BorderRadius.circular(8),
                minLength: MediaQuery.of(context).size.width - 1,
                maxLength: MediaQuery.of(context).size.width,
                height: 30,
              )),
        )
      ],
    ));
  }
}

class StatsSkeleton extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var r = Row(
      children: [
        SkeletonAvatar(
          style: SkeletonAvatarStyle(
              shape: BoxShape.circle, width: 30, height: 30),
        ),
        SizedBox(width: 8),
        SkeletonParagraph(
          style: SkeletonParagraphStyle(
              lines: 1,
              spacing: 6,
              lineStyle: SkeletonLineStyle(
                height: 20,
                borderRadius: BorderRadius.circular(8),
                minLength: (MediaQuery.of(context).size.width / 3) - 1,
                maxLength: MediaQuery.of(context).size.width / 3,
              )),
        ),
        Spacer(),
        SkeletonParagraph(
          style: SkeletonParagraphStyle(
              lines: 1,
              spacing: 6,
              lineStyle: SkeletonLineStyle(
                height: 20,
                borderRadius: BorderRadius.circular(8),
                minLength: (MediaQuery.of(context).size.width / 7) - 1,
                maxLength: MediaQuery.of(context).size.width / 7,
              )),
        )
      ],
    );

    return SkeletonItem(
        child: Column(children: List<Row>.filled(5, r)));
  }
}
