import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honeyday/app/app.dart';

/// Application entry point.
///
/// What: Bootstraps Flutter and wraps the root [HoneydayApp] with a global [ProviderScope].
/// Why: Provides Riverpod dependency injection and state management across all screens.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HoneydayApp()));
}
