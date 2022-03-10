import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutmeg/utils/Utils.dart';
import 'package:nutmeg/widgets/Containers.dart';
import 'package:skeletons/skeletons.dart';

class SkeletonAvailableMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoContainer(
      child: SkeletonItem(
        child: Row(
          children: [
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                borderRadius: BorderRadius.circular(8),
                width: 60,
                height: 78,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  SkeletonLine(
                    style: SkeletonLineStyle(
                        borderRadius: BorderRadius.circular(8),
                        width: 200,
                        height: 12),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  SkeletonLine(
                    style: SkeletonLineStyle(
                        borderRadius: BorderRadius.circular(8),
                        width: 120,
                        height: 12),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  SkeletonLine(
                    style: SkeletonLineStyle(
                        borderRadius: BorderRadius.circular(8),
                        width: 80,
                        height: 12),
                  )
                ],
              ),

              // child: SkeletonParagraph(
              //   style: SkeletonParagraphStyle(
              //       lines: 1,
              //       spacing: 15,
              //       lineStyle: SkeletonLineStyle(
              //         borderRadius: BorderRadius.circular(8),
              //         height: 12,
              //       )),
              // ),
            )
          ],
        ),
      ),
    );
  }
}

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
            minHeight: (MediaQuery.of(context).size.height / 5) - 1,
            maxHeight: MediaQuery.of(context).size.height / 5,
          ),
        ),
        SizedBox(height: 12),
        SkeletonParagraph(
          style: SkeletonParagraphStyle(
              lines: 3,
              spacing: 15,
              lineStyle: SkeletonLineStyle(
                borderRadius: BorderRadius.circular(8),
                minLength: MediaQuery.of(context).size.width - 1,
                maxLength: MediaQuery.of(context).size.width,
                height: 20,
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
