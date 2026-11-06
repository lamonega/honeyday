import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';
import 'package:honeyday/core/theme/app_fonts.dart';

/// Application entry point.
///
/// What: Bootstraps Flutter and wraps the root [HoneydayApp] with a global [ProviderScope].
/// Why: Provides Riverpod dependency injection and state management across all screens.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFonts.load();
  runApp(const ProviderScope(child: HoneydayApp()));
}
