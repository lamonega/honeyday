import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:honeyday/l10n/generated/app_localizations.dart';

import 'pump_app.dart';

/// Wraps a widget pumped by a third-party harness (such as Alchemist's
/// golden tests) in a fully configured [MaterialApp].
///
/// Alchemist builds its own localization scope with only the framework
/// defaults, so widgets calling `AppLocalizations.of(context)` throw a
/// null-check error, and `TextField`s assert on the missing
/// `MaterialLocalizations` above that scope. A nested `MaterialApp` provides
/// both without altering the rendered subtree.
class TestL10n extends StatelessWidget {
  const TestL10n({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
