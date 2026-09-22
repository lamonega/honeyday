import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

/// The locale every widget test renders with.
///
/// Tests assert against the Spanish ARB strings, so the locale must be pinned
/// instead of following the (English) host machine default.
const Locale kTestLocale = Locale('es');

/// A [MaterialApp] configured like the real app: localization delegates and
/// the pinned Spanish locale.
///
/// Drop-in replacement for the bare `MaterialApp` in widget tests, so widgets
/// that call `AppLocalizations.of(context)` do not throw a null-check error.
MaterialApp testMaterialApp({Widget? home}) {
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
