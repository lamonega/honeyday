import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/constants/preferences_keys.dart';
import 'package:honeyday/core/providers/shared_preferences_provider.dart';
import 'package:honeyday/core/theme/app_colors.dart';
import 'package:honeyday/core/theme/theme_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccentColorNotifier', () {
    test('pads hex correctly for non-opaque and low-value colors', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(accentColorProvider.future);
      await container
          .read(accentColorProvider.notifier)
          .set(const Color(0x000000FF));

      expect(prefs.getString(PreferencesKeys.accentColor), '0000FF');
      expect(
        container.read(accentColorProvider).value,
        const Color(0xFF0000FF),
      );

      await container
          .read(accentColorProvider.notifier)
          .set(const Color(0x0A123456));
      expect(prefs.getString(PreferencesKeys.accentColor), '123456');
      expect(
        container.read(accentColorProvider).value,
        const Color(0xFF123456),
      );
    });

    test(
      'rolls back state and throws StateError when setString returns false',
      () async {
        final prefs = _FailingPreferences(returnFalse: true);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
          ],
        );
        addTearDown(container.dispose);

        final initial = await container.read(accentColorProvider.future);
        expect(initial, AppColors.honeyAmber);

        await expectLater(
          container
              .read(accentColorProvider.notifier)
              .set(const Color(0xFF14B8A6)),
          throwsA(isA<StateError>()),
        );
        expect(container.read(accentColorProvider).value, AppColors.honeyAmber);
      },
    );

    test(
      'rolls back state and throws StateError when setString throws',
      () async {
        final prefs = _FailingPreferences(throwError: true);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
          ],
        );
        addTearDown(container.dispose);

        await container.read(accentColorProvider.future);

        await expectLater(
          container
              .read(accentColorProvider.notifier)
              .set(const Color(0xFF8B5CF6)),
          throwsA(isA<StateError>()),
        );
        expect(container.read(accentColorProvider).value, AppColors.honeyAmber);
      },
    );
  });

  group('ThemeModeNotifier', () {
    test(
      'rolls back state and throws StateError when setString fails',
      () async {
        final prefs = _FailingPreferences(returnFalse: true);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
          ],
        );
        addTearDown(container.dispose);

        final initial = await container.read(themeModeProvider.future);
        expect(initial, ThemeMode.system);

        await expectLater(
          container.read(themeModeProvider.notifier).set(ThemeMode.dark),
          throwsA(isA<StateError>()),
        );
        expect(container.read(themeModeProvider).value, ThemeMode.system);
      },
    );

    test(
      'rolls back state and throws StateError when setString throws',
      () async {
        final prefs = _FailingPreferences(throwError: true);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
          ],
        );
        addTearDown(container.dispose);

        await container.read(themeModeProvider.future);

        await expectLater(
          container.read(themeModeProvider.notifier).set(ThemeMode.light),
          throwsA(isA<StateError>()),
        );
        expect(container.read(themeModeProvider).value, ThemeMode.system);
      },
    );
  });
}

class _FailingPreferences implements SharedPreferences {
  _FailingPreferences({this.returnFalse = false, this.throwError = false});

  final bool returnFalse;
  final bool throwError;

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async {
    if (throwError) throw Exception('disk full');
    return !returnFalse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
