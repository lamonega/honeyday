import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';
import 'package:honeyday/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has completed onboarding (persisted).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

/// Root application widget for Honeyday.
///
/// What: Sets up declarative routing, Material 3 warm honey theming,
/// dynamic color support, system-adaptive light/dark mode, and onboarding.
/// Why: Acts as the primary entry point rendered within [ProviderScope].
class HoneydayApp extends ConsumerWidget {
  /// Constructs a [HoneydayApp].
  const HoneydayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = lightDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: AppColors.honeyAmber,
              brightness: Brightness.light,
            );
        final darkScheme = darkDynamic?.harmonized() ??
            ColorScheme.fromSeed(
              seedColor: AppColors.honeyAmber,
              brightness: Brightness.dark,
            );

        final lightTheme = HoneydayTheme.lightTheme.copyWith(
          colorScheme: lightScheme.copyWith(
            primary: AppColors.honeyAmber,
            onPrimary: Colors.white,
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
          themeMode: ThemeMode.system,
          routerConfig: showOnboarding ? _onboardingRouter : router,
        );
      },
    );
  }

  /// Minimal router that only shows onboarding.
  GoRouter get _onboardingRouter => GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const _OnboardingWrapper(),
          ),
        ],
      );
}

/// Wraps onboarding and handles navigation after completion.
class _OnboardingWrapper extends ConsumerWidget {
  const _OnboardingWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.completed) {
      // Persist and navigate to main app
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('onboarding_complete', true);
      });
      // Rebuild with main router
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(onboardingCompleteProvider);
      });
    }

    return const OnboardingPage();
  }
}
