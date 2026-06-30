import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_focus_scope.dart';

void main() {
  testWidgets('WindowFocusController debounces transient desktop blur events', (
    tester,
  ) async {
    var realWindowFocused = true;
    final controller = WindowFocusController()
      ..debugSetDesktopFocusVerifier(() async => realWindowFocused);
    addTearDown(controller.dispose);

    final changes = <bool>[];
    controller.addListener(() => changes.add(controller.isFocused));

    expect(controller.isFocused, isTrue);

    controller.onWindowBlur();
    expect(controller.isFocused, isTrue);

    await tester.pump(const Duration(milliseconds: 100));
    controller.onWindowFocus();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isFocused, isTrue);
    expect(changes, isEmpty);

    controller.onWindowBlur();
    await tester.pump(const Duration(milliseconds: 350));

    expect(controller.isFocused, isTrue);
    expect(changes, isEmpty);

    realWindowFocused = false;
    controller.onWindowBlur();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(controller.isFocused, isFalse);

    controller.onWindowFocus();
    expect(controller.isFocused, isTrue);

    realWindowFocused = true;
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(controller.isFocused, isTrue);

    await tester.pump(const Duration(milliseconds: 100));
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isFocused, isTrue);

    realWindowFocused = false;
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(controller.isFocused, isFalse);

    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.isFocused, isTrue);

    controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
    expect(controller.isFocused, isFalse);

    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.isFocused, isTrue);

    expect(changes, [false, true, false, true, false, true]);
  });

  testWidgets('WindowFocusScope defaults to focused when absent', (
    tester,
  ) async {
    late bool focused;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          focused = WindowFocusScope.isFocusedOf(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(focused, isTrue);
  });

  testWidgets('WindowFocusScope exposes focused state to descendants', (
    tester,
  ) async {
    late bool focused;
    await tester.pumpWidget(
      WindowFocusScope(
        focused: false,
        child: Builder(
          builder: (context) {
            focused = WindowFocusScope.isFocusedOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(focused, isFalse);
  });
}
