import 'package:clingfy/ui/platform/widgets/app_button.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('supports custom child content with width constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        builder: (context, child) => MacosTheme(
          data: buildMacosTheme(Theme.of(context).brightness),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: AppButton(
              onPressed: () {},
              minWidth: 140,
              child: const Text('Custom action'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Custom action'), findsOneWidget);
    final buttonFinder = find.byType(ElevatedButton);

    expect(buttonFinder, findsOneWidget);
    expect(tester.getSize(buttonFinder).width, greaterThanOrEqualTo(140));
  });
}
