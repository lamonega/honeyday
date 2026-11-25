import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/features/settings/presentation/pages/settings_page.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    SharedPreferences? prefs,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (prefs != null)
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'accent color picker exposes semantics, tooltips and cancel action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpSettings(tester);
        await tester.tap(find.text('Accent color'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(InkWell), findsWidgets);
        expect(find.byTooltip('Lavender'), findsOneWidget);
        expect(find.byTooltip('Honey bee'), findsOneWidget);

        final honeySemantics = tester.getSemantics(find.byTooltip('Honey bee'));
        expect(honeySemantics.label, contains('Honey bee'));

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('shows snackbar when saving accent color fails', (tester) async {
    await pumpSettings(tester, prefs: _FailingPrefs());
    await tester.tap(find.text('Accent color'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Lavender'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Could not save your changes. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Lavender'), findsNothing);
  });

  testWidgets('shows snackbar when saving theme mode fails', (tester) async {
    await pumpSettings(tester, prefs: _FailingPrefs());
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Could not save your changes. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Automatic (system)'), findsOneWidget);
  });
}

class _FailingPrefs implements SharedPreferences {
  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
