import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bundled typography shared by the application and offscreen PDF capture.
abstract final class AppFonts {
  static Future<void>? _loading;
  static bool _licensesRegistered = false;

  /// Disables network fetching and registers the bundled font licenses once.
  static void configure() {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (_licensesRegistered) return;
    _licensesRegistered = true;

    LicenseRegistry.addLicense(() async* {
      for (final entry in const {
        'Fraunces': 'OFL-Fraunces.txt',
        'PlusJakartaSans': 'OFL-PlusJakartaSans.txt',
        'Roboto': 'LICENSE-Roboto.txt',
      }.entries) {
        final license = await rootBundle.loadString(
          'assets/fonts/${entry.value}',
        );
        yield LicenseEntryWithLineBreaks([entry.key], license);
      }
    });
  }

  /// Preloads app typography before rendering, avoiding first-frame swaps.
  ///
  /// Roboto fallback is registered separately through Flutter's font manifest.
  ///
  /// Flutter bindings must be initialized before calling this method. Font
  /// files are resolved from assets, not from a previous device cache.
  static Future<void> load() {
    configure();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    for (final weight in [FontWeight.w400, FontWeight.w600, FontWeight.w700]) {
      GoogleFonts.fraunces(fontWeight: weight);
    }
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
    ]) {
      GoogleFonts.plusJakartaSans(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
  }
}
