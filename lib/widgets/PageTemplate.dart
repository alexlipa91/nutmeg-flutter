import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/RefresherWithObserverWidget.dart';


class PageTemplate extends StatelessWidget {
  final Function? initState;
  final Function? refreshState;
  final List<Widget> widgets;
  final Row? appBar;
  final Widget? bottomNavigationBar;
  final bool withBottomSafeArea;

  const PageTemplate({Key? key,
    this.refreshState,
    required this.widgets,
    this.appBar,
    this.bottomNavigationBar,
    this.initState,
    this.withBottomSafeArea = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var osRequiredPadding = MediaQuery.of(context).padding.bottom;
    var bottomPadding = (bottomNavigationBar != null) ? 16.0 : max(osRequiredPadding, 16.0);

    var refreshContainer = (Widget w) => (refreshState == null)
        ? Container(child: w)
        : RefresherWithObserverWidget(
      refreshState: refreshState!,
      child: w,
      initState: initState,
    );

    return Scaffold(
      backgroundColor: Palette.greyLightest,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: refreshContainer(CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            slivers: [
              SliverAppBar(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                centerTitle: false,
                titleSpacing: 0,
                title: appBar,
              ),
              SliverPadding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return widgets[index];
                    },
                    childCount: widgets.length,
                  ),
                ),
              )
            ],
          )),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
