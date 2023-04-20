import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';


/// A RefreshIndicator with a lifecycle observer.
/// The refreshState method is called in both cases
class RefresherWithObserverWidget extends StatefulWidget {

  final Widget child;
  final Function? initState;
  final Function refreshState;

  const RefresherWithObserverWidget({Key? key, required this.child,
    required this.refreshState, this.initState}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RefresherWithObserverWidgetState();
}

class RefresherWithObserverWidgetState extends State<RefresherWithObserverWidget> {

  final Logger _logger = Logger();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  late RefreshStateOnResumeObserver lifecycleEventHandler;

  @override
  void initState() {
    super.initState();
    lifecycleEventHandler = RefreshStateOnResumeObserver(
        resumeCallBack: () async {
          _logger.d("RefreshWithObserver: requesting refresh");
          _refreshIndicatorKey.currentState?.show();
        });
    WidgetsBinding.instance.addObserver(lifecycleEventHandler);
    _logger.d("RefreshWithObserver: calling refreshState in initState");
    if (widget.initState != null) {
      widget.initState!();
    }
    else {
      widget.refreshState();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(lifecycleEventHandler);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () => widget.refreshState(),
      child: widget.child,
    );
  }
}

class RefreshStateOnResumeObserver extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;

  RefreshStateOnResumeObserver({
    required this.resumeCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await resumeCallBack();
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

