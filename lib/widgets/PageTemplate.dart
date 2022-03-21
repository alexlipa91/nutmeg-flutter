import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PageTemplate extends StatelessWidget {
  final RefreshController refreshController = RefreshController();
  final Function refreshState;
  final List<Widget> widgets;
  final Row appBar;
  final Widget bottomNavigationBar;

  PageTemplate(
      {Key key,
      this.refreshState,
      this.widgets,
      this.appBar,
      this.bottomNavigationBar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var osRequiredPadding = MediaQuery.of(context).padding.bottom;
    var bottomPadding = (bottomNavigationBar != null) ? 16.0 : max(osRequiredPadding, 16.0);

    var refreshContainer = (Widget w) => (refreshState == null)
        ? Container(child: w)
        : SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            header: MaterialClassicHeader(),
            controller: refreshController,
            onRefresh: () async {
              await refreshState();
              refreshController.refreshToIdle();
            },
            child: w);

    return Scaffold(
      backgroundColor: Palette.grey_lightest,
      body: refreshContainer(SafeArea(
        bottom: false,
        child: CustomScrollView(
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
        ),
      )),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
