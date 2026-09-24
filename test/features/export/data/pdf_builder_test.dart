import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/export/data/pdf_builder.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

/// 1×1 transparent PNG used as a stand-in for a captured page.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  test('builds a %PDF document with one page per image', () async {
    final bytes = await buildPdf(
      pagePngs: [tinyPng, tinyPng],
      options: const ExportOptions(),
      title: 'Mi agenda',
    );
    final text = latin1.decode(bytes);

    expect(text, startsWith('%PDF'));
    expect(text, contains(RegExp(r'/Count\s+2\b')));
    expect(text, contains('/Title'));
  });

  test('Letter output uses the Letter media box', () async {
    final bytes = await buildPdf(
      pagePngs: [tinyPng],
      options: const ExportOptions(format: PdfExportFormat.letter),
      title: 'Agenda',
    );
    final text = latin1.decode(bytes);

    expect(text, contains(RegExp(r'612(\.0+)?\s+792(\.0+)?')));
    expect(text, contains(RegExp(r'/Count\s+1\b')));
  });
}
