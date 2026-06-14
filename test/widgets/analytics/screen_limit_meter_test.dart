import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upheal/widgets/analytics/screen_limit_meter.dart';
import 'package:upheal/models/dashboard_data.dart';
import 'package:upheal/theme/upheal_theme_data.dart';

Widget createTestApp({required DashboardData data, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? UpHealTheme.light()
        : UpHealTheme.dark(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: ScreenLimitMeter(data: data),
      ),
    ),
  );
}

void main() {
  group('ScreenLimitMeter', () {
    testWidgets('displays goal label and remaining time when under limit', (tester) async {
      final data = DashboardData(
        usageData: [
          {'appName': 'Test', 'usageTime': 1800000, 'category': 'Other'},
        ],
        focusScore: 50,
      );

      await tester.pumpWidget(createTestApp(data: data));
      await tester.pumpAndSettle();

      expect(find.text('30m / 2h goal'), findsOneWidget);
      expect(find.text('1h 30m left'), findsOneWidget);
    });

    testWidgets('displays overage text when over limit', (tester) async {
      final data = DashboardData(
        usageData: [
          {'appName': 'Test', 'usageTime': 36000000, 'category': 'Other'},
        ],
        focusScore: 50,
      );

      await tester.pumpWidget(createTestApp(data: data));
      await tester.pumpAndSettle();

      expect(find.text('10h / 2h goal'), findsOneWidget);
      expect(find.textContaining('over'), findsOneWidget);
    });

    testWidgets('displays exact limit label', (tester) async {
      final data = DashboardData(
        usageData: [
          {'appName': 'Test', 'usageTime': 7200000, 'category': 'Other'},
        ],
        focusScore: 50,
      );

      await tester.pumpWidget(createTestApp(data: data));
      await tester.pumpAndSettle();

      expect(find.text('2h / 2h goal'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      final data = DashboardData(
        usageData: [
          {'appName': 'Test', 'usageTime': 1800000, 'category': 'Other'},
        ],
        focusScore: 50,
      );

      await tester.pumpWidget(createTestApp(data: data, brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.text('30m / 2h goal'), findsOneWidget);
    });
  });
}
