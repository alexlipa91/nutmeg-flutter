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
    // fixme we apply safe area around body and if there is bottom bar we need to remove the bottom and manually add a space
    var minimumBottomPadding = (bottomNavigationBar != null) ? 0.0 : 16.0;
    if (bottomNavigationBar != null) {
      widgets.add(Container(child: SizedBox(height: 16.0)));
    }

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
      body: SafeArea(
        minimum: EdgeInsets.only(bottom: minimumBottomPadding),
        child: refreshContainer(CustomScrollView(
          slivers: [
            SliverAppBar(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              centerTitle: false,
              titleSpacing: 0,
              title: appBar,
            ),
            SliverPadding(
              padding: EdgeInsets.only(left: 16, right: 16),
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
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
