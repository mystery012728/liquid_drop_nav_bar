import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'liquid_capsule_painter.dart';
import 'liquid_drop_nav_bar_item.dart';

/// A customizable bottom navigation bar with a liquid droplet transition animation.
class LiquidDropNavBar extends StatefulWidget {
  /// The current selected tab index.
  final int currentIndex;

  /// Optional index of an item that should shrink/hide during transitions.
  final int? hiddenIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// The list of items to display.
  final List<LiquidDropNavBarItem> items;

  /// The outer margin of the navigation bar.
  final EdgeInsetsGeometry? margin;

  /// Callback executed when the transition animation completes.
  final VoidCallback? onAnimationCompleted;

  /// Height of the outer container. Defaults to 56.0.
  final double? height;

  /// Height of the moving liquid capsule. Defaults to 40.0.
  final double? capsuleHeight;

  /// Minimum width of the active tab's capsule. Defaults to 1.4 * [capsuleHeight].
  final double? minCapsuleWidth;

  /// Layout axis for active tab item content (horizontal for side-by-side, vertical for stacked).
  final Axis layoutAxis;

  /// Gap between icon and text. Defaults to 8.0 for horizontal, 2.0 for vertical.
  final double? gap;

  const LiquidDropNavBar({
    super.key,
    required this.currentIndex,
    this.hiddenIndex,
    required this.onTap,
    required this.items,
    this.margin,
    this.onAnimationCompleted,
    this.height,
    this.capsuleHeight,
    this.minCapsuleWidth,
    this.layoutAxis = Axis.horizontal,
    this.gap,
  }) : assert(items.length <= 5, 'LiquidDropNavBar only supports up to 5 items');

  @override
  State<LiquidDropNavBar> createState() => _LiquidDropNavBarState();
}

class _LiquidDropNavBarState extends State<LiquidDropNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _fromIndex;
  late int _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationCompleted?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiquidDropNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxIdx = widget.items.length - 1;
    if (_fromIndex > maxIdx) _fromIndex = maxIdx;
    if (_toIndex > maxIdx) _toIndex = maxIdx;

    if (widget.currentIndex != oldWidget.currentIndex) {
      _fromIndex = oldWidget.currentIndex.clamp(0, maxIdx);
      _toIndex = widget.currentIndex.clamp(0, maxIdx);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Measures the rendered width of a tab's pill (icon [+ gap + label] +
  // horizontal padding) so the traveling capsule can match the real
  // pill's size at both ends of the animation, instead of guessing.
  double _measurePillWidth({
    required bool selected,
    required String? label,
    required double minPillWidth,
  }) {
    if (widget.layoutAxis == Axis.vertical) {
      return minPillWidth;
    }
    const iconSize = 24.0;
    const horizontalPadding = 10.0;
    const gap = 6.0;

    double width = (horizontalPadding * 2) + iconSize;

    if (selected && label != null && label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      width += gap + textPainter.width;
    }

    double finalWidth = width;
    if (finalWidth < minPillWidth) {
      finalWidth = minPillWidth;
    }

    return finalWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final int itemCount = widget.items.length;
    final double baseMargin = widget.margin != null
        ? (widget.margin!.horizontal / 2)
        : (itemCount <= 3 ? 65.0 : 24.0);

    final Color barBgColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    final defaultHeight = widget.layoutAxis == Axis.vertical ? 72.0 : 56.0;
    final defaultCapHeight = widget.layoutAxis == Axis.vertical ? 52.0 : 40.0;

    final barHeight = widget.height ?? defaultHeight;
    final capHeight = widget.capsuleHeight ?? defaultCapHeight;
    final minPillWidth = widget.minCapsuleWidth ?? (capHeight * 1.4);

    final double defaultGap = widget.layoutAxis == Axis.vertical ? 2.0 : 8.0;
    final double actualGap = widget.gap ?? defaultGap;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isTraveling = _controller.isAnimating;

        // Safely clamp indices to current items length to prevent out-of-bounds exceptions
        final maxIdx = itemCount - 1;
        final safeFromIndex = _fromIndex.clamp(0, maxIdx);
        final safeToIndex = _toIndex.clamp(0, maxIdx);

        final bool hasHiddenItems = (safeToIndex - safeFromIndex).abs() > 1;

        // Calculate margin dynamically based on middle item shrink state
        EdgeInsetsGeometry margin;
        if (isTraveling && (widget.hiddenIndex != null || hasHiddenItems)) {
          final double tVal = _controller.value;
          double progress;
          if (tVal < 0.3) {
            progress = tVal / 0.3;
          } else if (tVal < 0.7) {
            progress = 1.0;
          } else {
            progress = 1.0 - (tVal - 0.7) / 0.3;
          }

          final Set<int> hiddenIndices = {};
          if (widget.hiddenIndex != null && widget.hiddenIndex! < itemCount) {
            hiddenIndices.add(widget.hiddenIndex!);
          }
          if (hasHiddenItems) {
            final int minIdx = math.min(safeFromIndex, safeToIndex);
            final int maxIdxVal = math.max(safeFromIndex, safeToIndex);
            for (int i = minIdx + 1; i < maxIdxVal; i++) {
              if (i < itemCount) {
                hiddenIndices.add(i);
              }
            }
          }
          final int numHidden = hiddenIndices.length;
          final int activeCount = itemCount - numHidden;

          double targetMargin = 24.0;
          if (activeCount == 3) {
            targetMargin = 65.0;
          } else if (activeCount <= 2) {
            targetMargin = 106.0;
          }

          final double currentHorizontalMargin =
              baseMargin + (targetMargin - baseMargin) * progress;
          margin = EdgeInsets.fromLTRB(
              currentHorizontalMargin, 0, currentHorizontalMargin, 55.0);
        } else {
          margin = widget.margin ??
              (itemCount <= 3
                  ? const EdgeInsets.fromLTRB(65.0, 0, 65.0, 55.0)
                  : const EdgeInsets.fromLTRB(24.0, 0, 24.0, 55.0));
        }

        return Container(
          margin: margin,
          height: barHeight,
          decoration: BoxDecoration(
            color: barBgColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const double paddingOffset = 12.0;
                  final double availableWidth = width - (paddingOffset * 2);
                  final List<double> wFactors = List.filled(itemCount, 1.0);

                  if (isTraveling &&
                      (widget.hiddenIndex != null || hasHiddenItems)) {
                    final double tVal = _controller.value;
                    double currentWF = 1.0;
                    if (tVal < 0.3) {
                      currentWF = 1.0 - (tVal / 0.3);
                    } else if (tVal < 0.7) {
                      currentWF = 0.0;
                    } else {
                      currentWF = (tVal - 0.7) / 0.3;
                    }
                    if (widget.hiddenIndex != null &&
                        widget.hiddenIndex! < itemCount) {
                      wFactors[widget.hiddenIndex!] = currentWF;
                    }
                    if (hasHiddenItems) {
                      final int minIdx = math.min(safeFromIndex, safeToIndex);
                      final int maxIdxVal = math.max(safeFromIndex, safeToIndex);
                      for (int i = minIdx + 1; i < maxIdxVal; i++) {
                        if (i < itemCount) {
                          wFactors[i] = currentWF;
                        }
                      }
                    }
                  }

                  double totalWF = 0.0;
                  for (final wf in wFactors) {
                    totalWF += wf;
                  }

                  final List<double> itemWidths = [];
                  for (int i = 0; i < itemCount; i++) {
                    itemWidths.add(availableWidth * (wFactors[i] / totalWF));
                  }

                  final List<double> centers = [];
                  double currentX = paddingOffset;
                  for (int i = 0; i < itemCount; i++) {
                    centers.add(currentX + itemWidths[i] / 2);
                    currentX += itemWidths[i];
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Traveling liquid capsule (only visible mid-transition).
                      if (isTraveling)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: LiquidCapsulePainter(
                              fromX: centers[safeFromIndex],
                              toX: centers[safeToIndex],
                              fromWidth: _measurePillWidth(
                                selected: true,
                                label: widget.items[safeFromIndex].label,
                                minPillWidth: minPillWidth,
                              ).clamp(
                                  0.0,
                                  (itemWidths[safeFromIndex] - 4.0)
                                      .clamp(0.0, double.infinity)),
                              toWidth: _measurePillWidth(
                                selected: true,
                                label: widget.items[safeToIndex].label,
                                minPillWidth: minPillWidth,
                              ).clamp(
                                  0.0,
                                  (itemWidths[safeToIndex] - 4.0)
                                      .clamp(0.0, double.infinity)),
                              capsuleHeight: capHeight,
                              barHeight: barHeight,
                              t: _controller.value,
                              color: colorScheme.secondary,
                              isAdjacent:
                                  true, // Always adjacent on the shrunken layout
                            ),
                          ),
                        ),

                      // Icon and Label Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: paddingOffset),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(itemCount, (index) {
                            final item = widget.items[index];
                            final isSelected = index == widget.currentIndex;

                            // Compute continuous activation progress (0.0 to 1.0) for this tab
                            double activeProgress;
                            if (isTraveling) {
                              if (index == safeToIndex) {
                                activeProgress = _controller.value;
                              } else if (index == safeFromIndex) {
                                activeProgress = 1.0 - _controller.value;
                              } else {
                                activeProgress = 0.0;
                              }
                            } else {
                              activeProgress = isSelected ? 1.0 : 0.0;
                            }

                            // Solid pill background color is only drawn when not transitioning,
                            // as the custom painter drives the background mid-transition.
                            final Color containerColor = isTraveling
                                ? Colors.transparent
                                : (isSelected
                                    ? colorScheme.secondary
                                    : Colors.transparent);

                            // Smoothly transition colors between grey (inactive) and primary/onSecondary (active)
                            final Color contentColor = Color.lerp(
                              colorScheme.secondary.withValues(alpha: 0.4),
                              colorScheme.onSecondary,
                              activeProgress,
                            )!;

                            // Dynamic width and opacity factors for the hidden items
                            double currentWF = 1.0;
                            double currentOpacity = 1.0;
                            final bool isThisHidden =
                                (isTraveling && widget.hiddenIndex == index) ||
                                    (isTraveling &&
                                        hasHiddenItems &&
                                        index >
                                            math.min(safeFromIndex, safeToIndex) &&
                                        index < math.max(safeFromIndex, safeToIndex));
                            if (isThisHidden) {
                              final double tVal = _controller.value;
                              if (tVal < 0.3) {
                                final double progress = tVal / 0.3;
                                currentWF = 1.0 - progress;
                                currentOpacity = 1.0 - progress;
                              } else if (tVal < 0.7) {
                                currentWF = 0.0;
                                currentOpacity = 0.0;
                              } else {
                                final double progress = (tVal - 0.7) / 0.3;
                                currentWF = progress;
                                currentOpacity = progress;
                              }
                            }

                            return Expanded(
                              flex: (currentWF * 100).toInt().clamp(1, 100),
                              child: Opacity(
                                opacity: currentOpacity.clamp(0.0, 1.0),
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.center,
                                    widthFactor: currentWF,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => widget.onTap(index),
                                      child: Center(
                                        child: Container(
                                          height: capHeight,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          constraints: () {
                                            final maxW = (itemWidths[index] -
                                                    4.0)
                                                .clamp(0.0, double.infinity);
                                            return BoxConstraints(
                                              minWidth: minPillWidth.clamp(
                                                  0.0, maxW),
                                              maxWidth: maxW,
                                            );
                                          }(),
                                          decoration: BoxDecoration(
                                            color: containerColor,
                                            borderRadius:
                                                BorderRadius.circular(99.0),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: widget.layoutAxis == Axis.vertical
                                                ? Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isSelected
                                                            ? item.activeIcon
                                                            : item.icon,
                                                        size: 24.0,
                                                        color: contentColor,
                                                      ),
                                                      if (activeProgress > 0.0 &&
                                                          item.label != null &&
                                                          item.label!
                                                              .isNotEmpty) ...[
                                                        SizedBox(
                                                            height: actualGap *
                                                                activeProgress),
                                                        Opacity(
                                                          opacity:
                                                              activeProgress,
                                                          child: Text(
                                                            item.label!,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  contentColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 10,
                                                              letterSpacing:
                                                                  0.1,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isSelected
                                                            ? item.activeIcon
                                                            : item.icon,
                                                        size: 24.0,
                                                        color: contentColor,
                                                      ),
                                                      if (activeProgress > 0.0 &&
                                                          item.label != null &&
                                                          item.label!
                                                              .isNotEmpty) ...[
                                                        SizedBox(
                                                            width: actualGap *
                                                                activeProgress),
                                                        Opacity(
                                                          opacity:
                                                              activeProgress,
                                                          child: Text(
                                                            item.label!,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  contentColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 13,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
