import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';

/// Application entry point.
///
/// What: Bootstraps Flutter and wraps the root [HoneydayApp] with a global [ProviderScope].
/// Why: Provides Riverpod dependency injection and state management across all screens.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow google_fonts to fetch Fraunces/Plus Jakarta Sans at runtime; the
  // previous `allowRuntimeFetching = false` had no bundled fonts to fall
  // back to, so the app silently rendered with the system font instead.
  // Tests disable fetching separately in flutter_test_config.dart.
  runApp(const ProviderScope(child: HoneydayApp()));
}
