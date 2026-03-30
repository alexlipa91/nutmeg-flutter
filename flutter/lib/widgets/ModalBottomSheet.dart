import 'package:flutter/material.dart';
import 'package:nutmeg/utils/UiUtils.dart';

class ModalBottomSheet {
  static bool isOpen = false;

  static Future<T?> showNutmegModalBottomSheet<T>(
    BuildContext? context,
    Widget child, {
    /// Pinned below scroll content (e.g. primary action). Stays visible when the sheet is tall.
    Widget? stickyBottom,
  }) async {
    isOpen = true;

    var returnValue;
    if (MediaQuery.of(context!).size.width <= 700) {
      returnValue = await showModalBottomSheet<T?>(
          isScrollControlled: true,
          backgroundColor: Palette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          context: context,
          builder: (BuildContext context) {
            final mq = MediaQuery.of(context);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: mq.size.height * 0.85,
              ),
              child: SafeArea(
                top: true,
                bottom: stickyBottom == null,
                minimum: stickyBottom == null
                    ? const EdgeInsets.only(bottom: 16)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Palette.greyLighter,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          top: 12,
                          right: 16,
                          left: 16,
                          bottom: 16,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Container(width: 1000, child: child),
                          ],
                        ),
                      ),
                    ),
                    if (stickyBottom != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16 + mq.padding.bottom,
                        ),
                        child: stickyBottom,
                      ),
                  ],
                ),
              ),
            );
          });
    } else {
      returnValue = await showDialog(
          context: context,
          builder: (BuildContext context) {
            final mq = MediaQuery.of(context);
            if (stickyBottom == null) {
              return Dialog(
                backgroundColor: Palette.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 16, top: 16, right: 16, left: 16),
                    child: Wrap(alignment: WrapAlignment.center, children: [
                      Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: child)
                    ])),
              );
            }
            return Dialog(
              backgroundColor: Palette.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mq.size.height * 0.85,
                  maxWidth: 500,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 16, right: 16, left: 16, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: child,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 8 + mq.padding.bottom,
                        ),
                        child: stickyBottom,
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
    }

    isOpen = false;

    return returnValue;
  }
}
