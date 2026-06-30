import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_flutter/app/window_chrome.dart';

void main() {
  testWidgets('renders custom Verdant window chrome controls', (tester) async {
    final controls = _FakeWindowChromeControls();

    await tester.pumpWidget(
      MaterialApp(
        home: VerdantWindowFrame(
          controls: controls,
          child: const SizedBox.expand(child: Text('content')),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('verdant-window-title-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('verdant-window-brand')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('verdant-window-app-icon')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('verdant-window-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('verdant-window-profile-badge')),
      findsNothing,
    );
    expect(find.text('Flutter client'), findsNothing);
    expect(
      find.byKey(const ValueKey('window-minimize-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('window-maximize-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('window-close-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('window-minimize-button')));
    await tester.tap(find.byKey(const ValueKey('window-maximize-button')));
    await tester.tap(find.byKey(const ValueKey('window-close-button')));

    expect(controls.minimizeCount, 1);
    expect(controls.maximizeCount, 1);
    expect(controls.closeCount, 1);
  });

  testWidgets('renders secondary test client badge when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VerdantWindowFrame(
          controls: _FakeWindowChromeControls(),
          profileBadgeLabel: 'Secondary Test Client',
          child: const SizedBox.expand(child: Text('content')),
        ),
      ),
    );

    expect(find.text('Verdant'), findsOneWidget);
    expect(find.text('Secondary Test Client'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('verdant-window-profile-badge')),
      findsOneWidget,
    );
  });
}

final class _FakeWindowChromeControls implements WindowChromeControls {
  int minimizeCount = 0;
  int maximizeCount = 0;
  int closeCount = 0;

  @override
  Future<void> close() async {
    closeCount += 1;
  }

  @override
  Future<void> minimize() async {
    minimizeCount += 1;
  }

  @override
  Future<void> toggleMaximize() async {
    maximizeCount += 1;
  }
}
