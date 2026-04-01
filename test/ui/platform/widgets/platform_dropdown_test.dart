import 'dart:ui';

import 'package:clingfy/ui/platform/widgets/platform_dropdown.dart' as app;
import 'package:clingfy/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDropdownApp({
    required ThemeMode themeMode,
    String? value = 'project',
    ValueChanged<String?>? onChanged,
    double width = 220,
    List<app.PlatformMenuItem<String>>? items,
  }) {
    return MaterialApp(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: app.PlatformDropdown<String>(
              value: value,
              onChanged: onChanged ?? (_) {},
              items:
                  items ??
                  const [
                    app.PlatformMenuItem(
                      value: 'project',
                      label:
                          'Very long project title that should not resize the popup button',
                    ),
                    app.PlatformMenuItem(
                      value: 'second',
                      label:
                          'Another wide option label to verify constrained selection rendering',
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }

  AnimatedContainer _dropdownField(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(app.PlatformDropdown<String>),
        matching: find.byKey(app.PlatformDropdown.fieldKey),
      ),
    );
  }

  Text _dropdownLabel(WidgetTester tester) {
    return tester.widget<Text>(
      find.descendant(
        of: find.byType(app.PlatformDropdown<String>),
        matching: find.byKey(app.PlatformDropdown.labelKey),
      ),
    );
  }

  Icon _dropdownArrow(WidgetTester tester) {
    return tester.widget<Icon>(
      find.descendant(
        of: find.byType(app.PlatformDropdown<String>),
        matching: find.byKey(app.PlatformDropdown.arrowKey),
      ),
    );
  }

  BoxDecoration _fieldDecoration(WidgetTester tester) {
    return _dropdownField(tester).decoration! as BoxDecoration;
  }

  BoxDecoration _menuRowDecoration(WidgetTester tester, int index) {
    return tester
            .widget<AnimatedContainer>(
              find.byKey(ValueKey('platform_dropdown_menu_row_$index')),
            )
            .decoration!
        as BoxDecoration;
  }

  Future<TestGesture> _hover(WidgetTester tester, Finder finder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  testWidgets(
    'selected labels stay constrained to the field width without overflow',
    (tester) async {
      await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byType(app.PlatformDropdown<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark theme uses custom field colors and normal arrow', (
    tester,
  ) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final decoration = _fieldDecoration(tester);
    final label = _dropdownLabel(tester);
    final arrow = _dropdownArrow(tester);

    expect(decoration.color, const Color(0xFF232428));
    expect(label.style?.color, const Color(0xFF797A7E));
    expect(arrow.icon, Icons.keyboard_arrow_down);
    expect(arrow.color, const Color(0xFF797A7E));
  });

  testWidgets('light theme uses custom field colors and text color', (
    tester,
  ) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    final decoration = _fieldDecoration(tester);
    final label = _dropdownLabel(tester);
    final arrow = _dropdownArrow(tester);

    expect(decoration.color, const Color(0xFFF3F4F7));
    expect(label.style?.color, const Color(0xFF5F636B));
    expect(arrow.color, const Color(0xFF5F636B));
  });

  testWidgets('opened menu grows wider than the closed field for long labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDropdownApp(
        themeMode: ThemeMode.dark,
        width: 220,
        items: const [
          app.PlatformMenuItem(value: 'short', label: 'Short'),
          app.PlatformMenuItem(
            value: 'long',
            label:
                'This is a much longer menu item label that should expand the opened menu width',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final fieldWidth = tester
        .getSize(find.byKey(app.PlatformDropdown.fieldKey))
        .width;

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    final menuRowWidth = tester
        .getSize(find.byKey(const ValueKey('platform_dropdown_menu_row_0')))
        .width;

    expect(menuRowWidth, greaterThan(fieldWidth));
  });

  testWidgets('opened menu width is clamped to a safe max width', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDropdownApp(
        themeMode: ThemeMode.dark,
        width: 220,
        items: const [
          app.PlatformMenuItem(value: 'short', label: 'Short'),
          app.PlatformMenuItem(
            value: 'huge',
            label:
                'This label is intentionally extremely long so the dropdown tries to expand far beyond the viewport safe width cap and should still be constrained cleanly without blowing out the popup layout in the widget test environment',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    final menuRowWidth = tester
        .getSize(find.byKey(const ValueKey('platform_dropdown_menu_row_0')))
        .width;

    expect(menuRowWidth, lessThanOrEqualTo(480));
  });

  testWidgets('closed field hover changes decoration', (tester) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final before = _fieldDecoration(tester);

    final gesture = await _hover(
      tester,
      find.byKey(app.PlatformDropdown.fieldKey),
    );
    final after = _fieldDecoration(tester);

    expect(after.color, isNot(before.color));
    expect(
      (after.border! as Border).top.color,
      isNot((before.border! as Border).top.color),
    );

    await gesture.removePointer();
  });

  testWidgets('open field state changes decoration', (tester) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final before = _fieldDecoration(tester);

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    final after = _fieldDecoration(tester);
    final arrow = _dropdownArrow(tester);

    expect(after.color, isNot(before.color));
    expect(
      (after.border! as Border).top.color,
      isNot((before.border! as Border).top.color),
    );
    expect(arrow.color, isNot(const Color(0xFF797A7E)));
  });

  testWidgets('selected row styling differs from unselected rows', (
    tester,
  ) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    final selected = _menuRowDecoration(tester, 0);
    final unselected = _menuRowDecoration(tester, 1);

    expect(selected.color, isNot(unselected.color));
  });

  testWidgets('hover styling appears on menu rows', (tester) async {
    await tester.pumpWidget(buildDropdownApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    final before = _menuRowDecoration(tester, 1);
    final gesture = await _hover(
      tester,
      find.byKey(const ValueKey('platform_dropdown_menu_row_1')),
    );
    final after = _menuRowDecoration(tester, 1);

    expect(after.color, isNot(before.color));

    await gesture.removePointer();
  });

  testWidgets('tapping opens menu and selecting item calls onChanged', (
    tester,
  ) async {
    String? changedValue;

    await tester.pumpWidget(
      buildDropdownApp(
        themeMode: ThemeMode.dark,
        onChanged: (value) {
          changedValue = value;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(app.PlatformDropdown.fieldKey));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Another wide option label to verify constrained selection rendering',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find
          .text(
            'Another wide option label to verify constrained selection rendering',
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(changedValue, 'second');
  });
}
