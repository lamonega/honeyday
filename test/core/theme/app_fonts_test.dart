import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:honeyday/core/theme/app_fonts.dart';
import 'package:honeyday/core/theme/theme_data.dart';

void main() {
  test(
    'all font files and licenses are bundled with verified checksums',
    () async {
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/fonts/manifest.json'),
      ) as Map<String, dynamic>;
      final files = (manifest['files'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets();
      expect(files, hasLength(17));
      expect(files.map((file) => file['file']).toSet(), hasLength(17));

      for (final file in files) {
        final path = 'assets/fonts/${file['file']}';
        expect(assets, contains(path));
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(bytes.length, file['bytes'], reason: path);
        expect(sha256.convert(bytes).toString(), file['sha256'], reason: path);
      }
    },
  );

  test('Roboto fallback is declared in the engine font manifest', () async {
    final manifest = (jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>).cast<Map<String, dynamic>>();
    final roboto = manifest.singleWhere((entry) => entry['family'] == 'Roboto');
    final fonts = (roboto['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(fonts.map((font) => font['weight']), [100, 300, 400, 500, 700, 900]);
    expect(
      fonts.map((font) => font['asset']),
      contains('assets/fonts/Roboto-Regular.ttf'),
    );
  });

  test(
    'font loading is idempotent and runtime fetching stays disabled',
    () async {
      final first = AppFonts.load();
      expect(AppFonts.load(), same(first));
      await first;
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
      await GoogleFonts.pendingFonts();
    },
  );

  test('each font license is available exactly once', () async {
    AppFonts.configure();
    AppFonts.configure();
    final entries = await LicenseRegistry.licenses.toList();
    for (final entry in const {
      'Fraunces': 'SIL OPEN FONT LICENSE Version 1.1',
      'PlusJakartaSans': 'SIL OPEN FONT LICENSE Version 1.1',
      'Roboto': 'Apache License',
    }.entries) {
      final matches = entries.where(
        (license) => license.packages.contains(entry.key),
      );
      expect(matches, hasLength(1));
      expect(
        matches.single.paragraphs.map((paragraph) => paragraph.text).join('\n'),
        contains(entry.value),
      );
    }
  });

  testWidgets(
    'both themes render real bundled fonts instead of Ahem fallback',
    (tester) async {
      for (final theme in [
        HoneydayTheme.lightTheme(),
        HoneydayTheme.darkTheme(),
      ]) {
        for (final style in [
          theme.textTheme.displayLarge!,
          theme.textTheme.titleLarge!,
          theme.textTheme.bodyMedium!,
          theme.textTheme.labelLarge!,
        ]) {
          const text = 'iiii WWWW Agenda, miércoles ¿Cómo estás?';
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          final fallback = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontFamily: 'Ahem', fontFamilyFallback: []),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(painter.width, isNot(closeTo(fallback.width, 1)));
          painter.dispose();
          fallback.dispose();
        }
      }
      await GoogleFonts.pendingFonts();
      expect(tester.takeException(), isNull);
    },
  );
}
