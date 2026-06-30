import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_design/moon_design.dart';
import 'package:verdant_flutter/theme/verdant_button.dart';
import 'package:verdant_flutter/theme/verdant_theme.dart';

void main() {
  testWidgets('primary VerdantButton uses the Moon filled button', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _buttonHost(VerdantButton(label: 'Sign In', onPressed: () => taps++)),
    );

    expect(find.byType(MoonFilledButton), findsOneWidget);
    expect(find.byType(MoonButton), findsOneWidget);

    await tester.tap(find.byType(MoonButton));
    await tester.pump(const Duration(milliseconds: 80));

    expect(taps, 1);
  });

  testWidgets('secondary and ghost variants use Moon variants', (tester) async {
    await tester.pumpWidget(
      _buttonHost(
        const Column(
          children: [
            VerdantButton(
              label: 'New API URL',
              onPressed: null,
              variant: VerdantButtonVariant.secondary,
            ),
            VerdantButton(
              label: 'Back to sign in',
              onPressed: null,
              variant: VerdantButtonVariant.ghost,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MoonOutlinedButton), findsOneWidget);
    expect(find.byType(MoonTextButton), findsOneWidget);
  });

  testWidgets('busy VerdantButton shows a Moon loader and blocks taps', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _buttonHost(
        VerdantButton(label: 'Sign In', isBusy: true, onPressed: () => taps++),
      ),
    );

    expect(find.byType(MoonCircularLoader), findsOneWidget);

    await tester.tap(find.byType(MoonButton));
    await tester.pump(const Duration(milliseconds: 80));

    expect(taps, 0);
  });

  testWidgets('disabled primary VerdantButton keeps readable white text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buttonHost(const VerdantButton(label: 'Upload Emoji', onPressed: null)),
    );

    final label = tester.widget<Text>(find.text('Upload Emoji'));
    expect(label.style?.color, VerdantThemeColors.dark.text);
  });
}

Widget _buttonHost(Widget child) {
  return MaterialApp(
    theme: buildVerdantTheme(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 240, child: child)),
    ),
  );
}
