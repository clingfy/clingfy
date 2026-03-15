import 'package:clingfy/app/home/widgets/home_loading_view.dart';
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLoadingView(WidgetTester tester, ThemeMode mode) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: mode,
        home: const HomeLoadingView(),
      ),
    );
  }

  testWidgets('renders startup loading UI with light shell gradient', (
    tester,
  ) async {
    await pumpLoadingView(tester, ThemeMode.light);

    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.byType(CupertinoActivityIndicator).evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('Loading your settings...'), findsOneWidget);

    final decoratedBox = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox).first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, buildLightTheme().appTokens.shellGradient.colors);
  });

  testWidgets('renders startup loading UI with dark shell gradient', (
    tester,
  ) async {
    await pumpLoadingView(tester, ThemeMode.dark);

    final decoratedBox = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox).first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, buildDarkTheme().appTokens.shellGradient.colors);
  });
}
