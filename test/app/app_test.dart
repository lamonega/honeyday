import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/app/app.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/database/persistent_storage_unavailable.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/core/theme/app_fonts.dart';
import 'package:honeyday/features/agendas/presentation/controllers/home_controller.dart';
import 'package:honeyday/features/agendas/presentation/pages/home_page.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:honeyday/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    AppFonts.configure();
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> openApp(
    WidgetTester tester, {
    String location = '/',
    Future<SharedPreferences>? preferences,
    bool failPreferences = false,
    bool storageUnavailable = false,
  }) async {
    await tester.runAsync(AppFonts.load);
    tester.platformDispatcher
      ..defaultRouteNameTestValue = location
      ..localesTestValue = const [Locale('es')]
      ..platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final container = ProviderContainer(
      retry: failPreferences ? (_, _) => null : null,
      overrides: [
        if (failPreferences)
          sharedPreferencesProvider.overrideWith(
            (ref) async => throw Exception('prefs failed'),
          )
        else if (preferences != null)
          sharedPreferencesProvider.overrideWith((ref) => preferences),
        agendasStreamProvider.overrideWith(
          (ref) => storageUnavailable
              ? Stream.error(const PersistentStorageUnavailable())
              : Stream.value([]),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HoneydayApp(),
      ),
    );
    return container;
  }

  testWidgets('completes onboarding at 320×568 in Spanish dark mode', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefsGate = Completer<SharedPreferences>();
    final app = await openApp(tester, preferences: prefsGate.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    prefsGate.complete(prefs);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
    for (final label in ['Siguiente', 'Siguiente', 'Comenzar']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byTooltip('Nueva Agenda'), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(
      app.read(routerProvider).routeInformationProvider.value.uri.path,
      '/',
    );
    expect(prefs.getBool(PreferencesKeys.onboardingComplete), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retains a deep link and allows retry after a failed write', (
    tester,
  ) async {
    final prefs = _FailOncePreferences();
    await openApp(
      tester,
      location: '/settings',
      preferences: Future.value(prefs),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);

    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(prefs.attempts, 2);
    expect(prefs.getBool(PreferencesKeys.onboardingComplete), isTrue);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('redirects a legacy onboarding URL to the home page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesKeys.onboardingComplete: true,
    });
    await openApp(tester, location: '/onboarding');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('blocks creating agendas when browser storage is unavailable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesKeys.onboardingComplete: true,
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openApp(tester, storageUnavailable: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('Este navegador no puede guardar'), findsOne);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the active shell branch alive when resizing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesKeys.onboardingComplete: true,
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(900, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openApp(tester, location: '/settings');
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    final settings = tester.element(find.byType(SettingsPage));

    tester.view.physicalSize = const Size(420, 600);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.element(find.byType(SettingsPage)), same(settings));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows storage guidance when preferences fail to initialize', (
    tester,
  ) async {
    await openApp(tester, failPreferences: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('Este navegador no puede guardar'), findsOne);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not flash bootstrap splash when completing onboarding', (
    tester,
  ) async {
    await openApp(tester);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.tap(find.text('Saltar'));
    // Pump single frames while onboardingCompleteProvider reloads.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
  });
}

class _FailOncePreferences implements SharedPreferences {
  int attempts = 0;
  bool? _completed;

  @override
  bool? getBool(String key) => _completed;

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setBool(String key, bool value) async {
    if (++attempts == 1) return false;
    _completed = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
