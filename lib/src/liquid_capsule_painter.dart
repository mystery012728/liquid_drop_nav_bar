import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints a capsule (pill) that travels from one tab's position to another,
/// using a 2-blob gooey metaball model that stretches, forms a neck, snaps
/// at the midpoint, and lands with an organic wobbly landing.
///
/// Colors are passed in from the caller so this painter
/// never hardcodes theme colors.
class LiquidCapsulePainter extends CustomPainter {
  final double fromX;
  final double toX;
  final double fromWidth;
  final double toWidth;
  final double capsuleHeight;
  final double barHeight;
  final double t; // 0 -> 1 animation progress
  final Color color;
  final bool isAdjacent;

  LiquidCapsulePainter({
    required this.fromX,
    required this.toX,
    required this.fromWidth,
    required this.toWidth,
    required this.capsuleHeight,
    required this.barHeight,
    required this.t,
    required this.color,
    required this.isAdjacent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double centerY = barHeight / 2;

    if (!isAdjacent) {
      // 1. SHRINK, TRAVEL, EXPAND ANIMATION FOR NON-ADJACENT TABS
      double currentWidth;
      double currentHeight;
      double currentX;

      if (t < 0.3) {
        final double progress = Curves.easeInOut.transform(t / 0.3);
        currentWidth = fromWidth + (capsuleHeight - fromWidth) * progress;
        currentHeight = capsuleHeight;
        currentX = fromX;
      } else if (t < 0.7) {
        final double progress = (t - 0.3) / 0.4;
        final double travelProgress = Curves.easeInOut.transform(progress);
        currentX = fromX + (toX - fromX) * travelProgress;

        final double travelSine = math.sin(progress * math.pi);
        currentWidth = capsuleHeight * (1.0 + 0.25 * travelSine);
        currentHeight = capsuleHeight * (1.0 - 0.12 * travelSine);
      } else {
        final double progress = (t - 0.7) / 0.3;
        currentX = toX;
        final double bounce = math.sin(progress * math.pi * 2.5) * math.exp(-progress * 4.0);
        currentWidth = capsuleHeight + (toWidth - capsuleHeight) * progress + (toWidth * 0.15 * bounce);
        currentHeight = capsuleHeight * (1.0 - 0.1 * bounce);
      }

      final double r = currentHeight / 2;
      final double finalWidth = math.max(currentWidth, currentHeight);
      final rect = Rect.fromCenter(
        center: Offset(currentX, centerY),
        width: finalWidth,
        height: currentHeight,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));
      canvas.drawRRect(rrect, paint);
      return;
    }

    // The snap point of the neck is at t = 0.5
    const double tSnap = 0.5;
    final bool isMovingRight = fromX < toX;
    final double pullX = (toX - fromX) * 0.06;
    final double h = capsuleHeight;
    final double r = h / 2;

    // We use custom curves to build up tension before snapping,
    // and ease out retraction after snapping.
    if (t < tSnap) {
      // 1. STRETCH & BRIDGE PHASE (t goes from 0.0 to tSnap)
      // Ease in progress to create tension (slow start, rapid stretch at snap)
      final double linearProgress = t / tSnap;
      final double progress = Curves.easeInQuad.transform(linearProgress);

      // Compute continuous widths
      final double wSrcCurrent = fromWidth * (1.0 - 0.3 * progress);
      final double wDstCurrent = toWidth * (0.3 + 0.45 * progress);

      final double finalSrcWidth = math.max(wSrcCurrent, h);
      final double finalDstWidth = math.max(wDstCurrent, h);

      // Symmetrical pull on centers
      final double xSrcCurrent = fromX + pullX * progress;
      final double xDstCurrent = toX - pullX * (1.0 - progress);

      // Draw Source Capsule
      final srcRect = Rect.fromCenter(
        center: Offset(xSrcCurrent, centerY),
        width: finalSrcWidth,
        height: h,
      );
      final srcRRect = RRect.fromRectAndRadius(srcRect, Radius.circular(r));
      canvas.drawRRect(srcRRect, paint);

      // Draw Destination Capsule
      final dstRect = Rect.fromCenter(
        center: Offset(xDstCurrent, centerY),
        width: finalDstWidth,
        height: h,
      );
      final dstRRect = RRect.fromRectAndRadius(dstRect, Radius.circular(r));
      canvas.drawRRect(dstRRect, paint);

      // Treat the inner end-caps as circles to compute gooey connection
      // x1 is the right side of the left capsule's end cap circle
      final double x1 = isMovingRight
          ? (xSrcCurrent + finalSrcWidth / 2 - r)
          : (xDstCurrent + finalDstWidth / 2 - r);
      // x2 is the left side of the right capsule's end cap circle
      final double x2 = isMovingRight
          ? (xDstCurrent - finalDstWidth / 2 + r)
          : (xSrcCurrent - finalSrcWidth / 2 + r);

      final double distance = (x2 - x1).abs();

      if (distance > 0.01 && distance < r * 8) {
        final double xMid = (x1 + x2) / 2;
        // The neck radius shrinks non-linearly to simulate liquid tension,
        // but maintains a minimum rounded curve before snapping to avoid sharp point.
        final double neckRadius = r * math.max(0.2, math.pow(1.0 - progress, 1.5));
        final double dx = distance * 0.3; // control point horizontal distance

        final bridgePath = Path();
        // Top edge: Left end-cap top to Mid, then Mid to Right end-cap top
        bridgePath.moveTo(x1, centerY - r);
        bridgePath.cubicTo(
          x1 + dx, centerY - r,
          xMid - dx, centerY - neckRadius,
          xMid, centerY - neckRadius,
        );
        bridgePath.cubicTo(
          xMid + dx, centerY - neckRadius,
          x2 - dx, centerY - r,
          x2, centerY - r,
        );
        // Line down on right edge
        bridgePath.lineTo(x2, centerY + r);
        // Bottom edge: Right end-cap bottom to Mid, then Mid to Left end-cap bottom
        bridgePath.cubicTo(
          x2 - dx, centerY + r,
          xMid + dx, centerY + neckRadius,
          xMid, centerY + neckRadius,
        );
        bridgePath.cubicTo(
          xMid - dx, centerY + neckRadius,
          x1 + dx, centerY + r,
          x1, centerY + r,
        );
        bridgePath.close();

        canvas.drawPath(bridgePath, paint);
      }
    } else {
      // 2. SNAP, RETRACT & BOUNCE PHASE (t goes from tSnap to 1.0)
      final double tRetract = (t - tSnap) / (1.0 - tSnap); // Normalize to 0.0 -> 1.0

      // Damped sine wave for vertical squash/stretch
      final double bounce = math.sin(tRetract * math.pi * 3.5) * math.exp(-tRetract * 4.0);

      // Horizontal wobble sine wave for lateral sloshing
      final double wobbleX = (toX - fromX) * 0.05 * math.sin(tRetract * math.pi * 2.5) * math.exp(-tRetract * 4.0);

      // Calculate initial tail length based on the separation at snap moment (t = 0.5)
      final double wSrcSnap = fromWidth * 0.7;
      final double wDstSnap = toWidth * 0.75;
      final double xSrcSnap = fromX + pullX;
      final double xDstSnap = toX;
      final double c1SnapX = xSrcSnap + (isMovingRight ? wSrcSnap / 2 - r : -wSrcSnap / 2 + r);
      final double c2SnapX = xDstSnap + (isMovingRight ? -wDstSnap / 2 + r : wDstSnap / 2 - r);
      final double dSnap = (c2SnapX - c1SnapX).abs();

      final double tailLengthSrc = (dSnap / 2) * (1.0 - Curves.easeOutQuad.transform(tRetract));
      final double tailLengthDst = (dSnap / 2) * (1.0 - tRetract);

      // Destination center is offset by wobble
      final double xDstCurrent = toX + wobbleX;
      // Width is continuous at snap (t = 0.5 -> wDstBase = toWidth * 0.75)
      final double wDstBase = toWidth * (0.525 + 0.475 * t);
      final double wDst = wDstBase * (1.0 + 0.16 * bounce);
      final double hDst = capsuleHeight * (1.0 - 0.12 * bounce);
      final double rDst = hDst / 2;

      final double finalDstWidth = math.max(wDst, hDst);
      final dstRect = Rect.fromCenter(
        center: Offset(xDstCurrent, centerY),
        width: finalDstWidth,
        height: hDst,
      );
      final dstRRect = RRect.fromRectAndRadius(dstRect, Radius.circular(rDst));
      canvas.drawRRect(dstRRect, paint);

      // Draw destination tail pointing back towards source
      if (tailLengthDst > 0.01) {
        final double dirDst = isMovingRight ? -1.0 : 1.0;
        final double cDstX = xDstCurrent + (isMovingRight ? -finalDstWidth / 2 + rDst : finalDstWidth / 2 - rDst);
        final tailPathDst = _getTailPath(cDstX, centerY, rDst, tailLengthDst, dirDst);
        canvas.drawPath(tailPathDst, paint);
      }

      // Source tail snaps and flies towards destination
      final double tSrcRetract = Curves.easeOutQuad.transform(tRetract);

      if (tSrcRetract < 1.0) {
        final solidPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        // Width is continuous at snap (t = 0.5 -> wSrcBase = fromWidth * 0.85)
        final double wSrcBase = fromWidth * 0.85;
        final double wSrc = wSrcBase * (1.0 - tSrcRetract);
        final double hSrc = capsuleHeight * (1.0 - tSrcRetract);
        final double rSrc = hSrc / 2;
        final double xSrcCurrent = fromX + (toX - fromX) * (0.06 + 0.14 * tSrcRetract);

        final double finalSrcWidth = math.max(wSrc, hSrc);

        if (finalSrcWidth > 0.1 && hSrc > 0.1) {
          final srcRect = Rect.fromCenter(
            center: Offset(xSrcCurrent, centerY),
            width: finalSrcWidth,
            height: hSrc,
          );
          final srcRRect = RRect.fromRectAndRadius(srcRect, Radius.circular(rSrc));
          canvas.drawRRect(srcRRect, solidPaint);

          // Draw source tail pointing towards destination
          if (tailLengthSrc > 0.01) {
            final double dirSrc = isMovingRight ? 1.0 : -1.0;
            final double cSrcX = xSrcCurrent + (isMovingRight ? finalSrcWidth / 2 - rSrc : -finalSrcWidth / 2 + rSrc);
            final tailPathSrc = _getTailPath(cSrcX, centerY, rSrc, tailLengthSrc, dirSrc);
            canvas.drawPath(tailPathSrc, solidPaint);
          }
        }
      }
    }
  }

  Path _getTailPath(double centerX, double centerY, double r, double tailLength, double dir) {
    final path = Path();

    // Choose tip radius: base it on r, but scale down for short tails so it doesn't exceed tailLength.
    double rTip = r * 0.25;
    if (rTip > tailLength * 0.5) {
      rTip = tailLength * 0.5;
    }

    // If tail length is extremely small, just return an empty path to avoid division/coordinates issues.
    if (tailLength < 0.1 || rTip < 0.05) {
      return path;
    }

    final double xTip = centerX + dir * tailLength;
    final double tipCenter = xTip - dir * rTip;

    final double pTipTopX = tipCenter;
    final double pTipTopY = centerY - rTip;
    final double pTipBottomX = tipCenter;
    final double pTipBottomY = centerY + rTip;

    path.moveTo(centerX, centerY - r);

    // Top curve: starts horizontal at (centerX, centerY - r)
    // and ends horizontal at (pTipTopX, pTipTopY).
    path.cubicTo(
      centerX + dir * tailLength * 0.35, centerY - r,
      pTipTopX - dir * tailLength * 0.15, pTipTopY,
      pTipTopX, pTipTopY,
    );

    // Round tip cap: semi-circle from top to bottom
    path.arcToPoint(
      Offset(pTipBottomX, pTipBottomY),
      radius: Radius.circular(rTip),
      clockwise: dir > 0,
    );

    // Bottom curve: starts horizontal at (pTipBottomX, pTipBottomY)
    // and ends horizontal at (centerX, centerY + r).
    path.cubicTo(
      pTipBottomX - dir * tailLength * 0.15, pTipBottomY,
      centerX + dir * tailLength * 0.35, centerY + r,
      centerX, centerY + r,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant LiquidCapsulePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.fromX != fromX ||
        oldDelegate.toX != toX ||
        oldDelegate.fromWidth != fromWidth ||
        oldDelegate.toWidth != toWidth ||
        oldDelegate.color != color ||
        oldDelegate.isAdjacent != isAdjacent;
  }
}
