import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Rect _shareOriginRect(BuildContext context) {
  Rect clampToBounds(Rect rect, Rect bounds) {
    final clamped = rect.intersect(bounds);
    if (clamped.width > 0 && clamped.height > 0) return clamped;

    // iOS requires a non-zero rect fully contained in source view.
    final center = bounds.center;
    return Rect.fromCenter(center: center, width: 1, height: 1);
  }

  final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final overlayBounds = overlayBox != null && overlayBox.hasSize
      ? (Offset.zero & overlayBox.size)
      : (Offset.zero & MediaQuery.of(context).size);

  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox != null &&
      renderBox.hasSize &&
      renderBox.size.width > 0 &&
      renderBox.size.height > 0) {
    final globalRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    return clampToBounds(globalRect, overlayBounds);
  }

  if (overlayBounds.width > 0 && overlayBounds.height > 0) {
    return clampToBounds(overlayBounds, overlayBounds);
  }

  final size = MediaQuery.of(context).size;
  final fallbackBounds = Rect.fromLTWH(0, 0, size.width, size.height);
  return clampToBounds(fallbackBounds, fallbackBounds);
}

Future<ShareResult> shareWithOrigin(
  BuildContext context, {
  String? text,
  String? subject,
  String? title,
  List<XFile>? files,
}) {
  return SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: subject,
      title: title,
      files: files,
      sharePositionOrigin: _shareOriginRect(context),
    ),
  );
}
