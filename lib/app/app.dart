import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared instance of [SharedPreferences] available app-wide.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Whether the user has completed onboarding (persisted).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('onboarding_complete') ?? false;
});

/// Minimal router that only shows onboarding.
final _onboardingRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const _OnboardingWrapper(),
    ),
  ],
);

/// Root application widget for Honeyday.
class HoneydayApp extends ConsumerWidget {
  const HoneydayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme =
            lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: AppColors.honeyAmber);
        final darkScheme =
            darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: AppColors.honeyAmber,
              brightness: Brightness.dark,
            );

        final lightTheme = HoneydayTheme.lightTheme.copyWith(
          colorScheme: lightScheme.copyWith(
            primary: AppColors.honeyAmber,
            onPrimary: AppColors.paperSurface,
            primaryContainer: AppColors.honeyContainer,
            onPrimaryContainer: AppColors.honeyDark,
          ),
        );
        final darkTheme = HoneydayTheme.darkTheme.copyWith(
          colorScheme: darkScheme.copyWith(
            primary: AppColors.honeyAmberDark,
            onPrimary: AppColors.paperDark,
            primaryContainer: AppColors.honeyContainerDark,
            onPrimaryContainer: AppColors.honeyDarkOnDark,
          ),
        );

        final bool showOnboarding;
        if (onboardingAsync is AsyncData<bool>) {
          showOnboarding = !onboardingAsync.value;
        } else {
          showOnboarding = false;
        }

        return MaterialApp.router(
          title: 'Honeyday',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: showOnboarding ? _onboardingRouter : router,
        );
      },
    );
  }
}

/// Wraps onboarding and handles navigation after completion.
class _OnboardingWrapper extends ConsumerStatefulWidget {
  const _OnboardingWrapper();

  @override
  ConsumerState<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<_OnboardingWrapper> {
  bool _persisted = false;

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.completed && !_persisted) {
      _persisted = true;
      unawaited(
        ref.read(sharedPreferencesProvider.future).then((prefs) {
          unawaited(prefs.setBool('onboarding_complete', true));
        }),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(onboardingCompleteProvider);
      });
    }

    return const OnboardingPage();
  }
}
