import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/router.dart';
import 'package:honeyday/app/theme.dart';

/// Root application widget for Honeyday.
///
/// What: Sets up declarative routing, Material 3 warm honey theming, and localization support.
/// Why: Acts as the primary entry point rendered within [ProviderScope].
class HoneydayApp extends ConsumerWidget {
  /// Constructs a [HoneydayApp].
  const HoneydayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Honeyday',
      debugShowCheckedModeBanner: false,
      theme: HoneydayTheme.lightTheme,
      routerConfig: router,
    );
  }
}
