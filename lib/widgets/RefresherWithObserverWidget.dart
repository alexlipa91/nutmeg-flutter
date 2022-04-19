import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../utils/UiUtils.dart';

/// A SmartRefresher with a lifecycle observer.
/// The refreshState method is called in both cases
class RefresherWithObserverWidget extends StatefulWidget {

  final Widget child;
  final Function refreshState;

  const RefresherWithObserverWidget({Key key, this.child, this.refreshState}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RefresherWithObserverWidgetState();
}

class RefresherWithObserverWidgetState extends State<RefresherWithObserverWidget> {

  final Logger _logger = Logger();

  RefreshStateOnResumeObserver lifecycleEventHandler;
  final RefreshController refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    lifecycleEventHandler = RefreshStateOnResumeObserver(
        resumeCallBack: () async {
          _logger.d("RefreshWithObserver: requesting refresh");
          await refreshController.requestRefresh();
        });
    WidgetsBinding.instance.addObserver(lifecycleEventHandler);
    _logger.d("RefreshWithObserver: calling refreshState in initState");
    widget.refreshState();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(lifecycleEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        header: MaterialClassicHeader(color: Palette.primary),
        controller: refreshController,
        onRefresh: () async {
          _logger.d("RefreshWithObserver: calling SmartRefresher onRefresh");
          await Future.delayed(Duration(seconds: 3));
          await widget.refreshState();
          refreshController.refreshCompleted();
        },
        child: widget.child);
  }
}

class RefreshStateOnResumeObserver extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;

  RefreshStateOnResumeObserver({
    this.resumeCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }
}

