import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone configuration for layout tests: logical size, system font scale
/// and the system bars the app draws behind (it is edge-to-edge).
class PhoneViewport {
  const PhoneViewport(
    this.name,
    this.size, {
    this.textScale = 1.0,
    this.statusBar = 36,
    this.navBar = 24,
  });

  final String name;
  final Size size;
  final double textScale;
  final double statusBar;
  final double navBar;

  @override
  String toString() =>
      '$name ${size.width.toInt()}x${size.height.toInt()} @${textScale}x';
}

/// Phones every screen must fit: a common Xiaomi size, MIUI's large font
/// settings, a compact screen, 3-button navigation and landscape.
const phoneViewports = <PhoneViewport>[
  PhoneViewport('xiaomi', Size(393, 873)),
  PhoneViewport('xiaomi', Size(393, 873), textScale: 1.5),
  PhoneViewport('xiaomi', Size(393, 873), textScale: 2.0),
  PhoneViewport('compact', Size(360, 640), textScale: 1.5),
  PhoneViewport('compact-3-button-nav', Size(360, 640), navBar: 48),
  PhoneViewport('landscape', Size(873, 393), statusBar: 24, navBar: 16),
];

/// Makes the test window look like [v]. Call before pumpWidget.
void applyViewport(WidgetTester tester, PhoneViewport v) {
  const dpr = 3.0;
  tester.view.physicalSize = v.size * dpr;
  tester.view.devicePixelRatio = dpr;
  final insets = FakeViewPadding(
    top: v.statusBar * dpr,
    bottom: v.navBar * dpr,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.platformDispatcher.textScaleFactorTestValue = v.textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Iterable<Rect> _onScreenTextRects(WidgetTester tester, Size screen) sync* {
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    // Other PageView pages sit fully left/right of the screen.
    if (rect.right <= 0 || rect.left >= screen.width) continue;
    yield rect;
  }
}

/// Fails if any text starts under the status bar or spills past the side
/// edges, or if — after scrolling every vertical scrollable to its end —
/// some text still ends under the navigation bar (it could never be read).
///
/// This catches content that silently runs off-screen without a RenderFlex
/// overflow error (e.g. a ListTile squeezed into an Expanded). The test font
/// is wider than Satoshi, so these checks are pessimistic — a safety margin.
Future<void> expectContentFitsScreen(
  WidgetTester tester,
  PhoneViewport v,
) async {
  const tolerance = 0.5;
  for (final rect in _onScreenTextRects(tester, v.size)) {
    expect(
      rect.top,
      greaterThanOrEqualTo(v.statusBar - tolerance),
      reason: 'text at $rect starts under the status bar on $v',
    );
    expect(
      rect.left,
      greaterThanOrEqualTo(-tolerance),
      reason: 'text at $rect spills past the left edge on $v',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(v.size.width + tolerance),
      reason: 'text at $rect spills past the right edge on $v',
    );
  }

  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  await tester.pump();

  final bottoms = _onScreenTextRects(tester, v.size).map((r) => r.bottom);
  final lowest = bottoms.isEmpty ? 0.0 : bottoms.reduce(math.max);
  expect(
    lowest,
    lessThanOrEqualTo(v.size.height - v.navBar + tolerance),
    reason: 'content ends at $lowest, under the navigation bar on $v',
  );
}
