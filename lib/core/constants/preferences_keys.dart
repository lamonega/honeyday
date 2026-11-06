/// SharedPreferences keys used across the app.
abstract final class PreferencesKeys {
  /// Whether the user has completed onboarding.
  static const String onboardingComplete = 'onboarding_complete';

  /// Theme mode preference ('light' or 'dark').
  static const String themeMode = 'theme_mode';

  /// User-selected accent color hex value.
  static const String accentColor = 'accent_color';

  /// Page identity last visited in an agenda (never an order-dependent index).
  static String lastPage(String agendaId) => 'agenda_last_page_$agendaId';
}
