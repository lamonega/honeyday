import 'package:flutter/material.dart';

class AppLocalizations {
  final Map<String, String> _localizedStrings;

  AppLocalizations(this._localizedStrings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get newAgenda => _localizedStrings['newAgenda']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // En producción esto cargaría el archivo .arb correspondiente.
    return AppLocalizations({'newAgenda': 'Nueva Agenda'});
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
