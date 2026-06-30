import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/shared/smooth_single_child_scroll_view.dart';

void main() {
  testWidgets('mouse wheel scroll animates instead of jumping', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 200,
            child: SmoothSingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  for (var index = 0; index < 20; index += 1)
                    SizedBox(height: 48, child: Text('row $index')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    tester.binding.handlePointerEvent(
      const PointerScrollEvent(
        position: Offset(80, 80),
        scrollDelta: Offset(0, 120),
      ),
    );
    await tester.pump();

    expect(controller.offset, 0);

    await tester.pump(const Duration(milliseconds: 80));

    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(120));

    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(120, 0.5));
  });

  testWidgets('smooth wheel wrapper can be reused with lazy scrollables', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 200,
            child: SmoothWheelScroll(
              controller: controller,
              child: ListView.builder(
                controller: controller,
                itemCount: 40,
                itemBuilder: (context, index) =>
                    SizedBox(height: 48, child: Text('lazy row $index')),
              ),
            ),
          ),
        ),
      ),
    );

    tester.binding.handlePointerEvent(
      const PointerScrollEvent(
        position: Offset(80, 80),
        scrollDelta: Offset(0, 120),
      ),
    );
    await tester.pump();

    expect(controller.offset, 0);

    await tester.pump(const Duration(milliseconds: 80));

    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(120));

    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(120, 0.5));
  });

  testWidgets('reset token clears stale smooth wheel targets', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var resetToken = 0;

    Widget buildHarness() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 200,
            child: SmoothWheelScroll(
              controller: controller,
              resetToken: resetToken,
              child: ListView.builder(
                controller: controller,
                itemCount: 80,
                itemBuilder: (context, index) =>
                    SizedBox(height: 48, child: Text('lazy row $index')),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHarness());

    tester.binding.handlePointerEvent(
      const PointerScrollEvent(
        position: Offset(80, 80),
        scrollDelta: Offset(0, 240),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    controller.jumpTo(900);
    resetToken += 1;
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    tester.binding.handlePointerEvent(
      const PointerScrollEvent(
        position: Offset(80, 80),
        scrollDelta: Offset(0, 120),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.offset, closeTo(1020, 1));
  });
}
