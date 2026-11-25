import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/theme/app_fonts.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

void main() {
  setUp(AppFonts.configure);

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    VoidCallback? onComplete,
    double textScale = 1.0,
  }) async {
    await tester.runAsync(AppFonts.load);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: OnboardingPage(onComplete: onComplete ?? () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('supports back button navigation on steps > 0', (tester) async {
    await pumpOnboarding(tester);

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Organize your life'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Draw freely'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Organize your life'), findsOneWidget);
  });

  testWidgets('supports jumping between steps by tapping pagination dots', (
    tester,
  ) async {
    var completed = false;
    await pumpOnboarding(tester, onComplete: () => completed = true);

    final dots = find.ancestor(
      of: find.byType(AnimatedContainer),
      matching: find.byType(InkWell),
    );
    expect(dots, findsNWidgets(3));

    await tester.tap(dots.at(2));
    await tester.pumpAndSettle();
    expect(find.text('Customize everything'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(dots.at(0));
    await tester.pumpAndSettle();
    expect(find.text('Organize your life'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(completed, isFalse);
  });

  testWidgets('renders without overflow at large text scale', (tester) async {
    await pumpOnboarding(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
