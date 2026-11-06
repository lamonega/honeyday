import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/export/data/offscreen_capture.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

import '../../../helpers/pump_app.dart';

/// Reads a sample pixel from the actual compressed RGB image in the PDF.
List<int> _pdfPixel(Uint8List bytes, int imageIndex, int x, int y) {
  final text = latin1.decode(bytes);
  final imageAt = text.indexOf('/Subtype /Image /Name /Im$imageIndex ');
  expect(imageAt, greaterThanOrEqualTo(0));
  final streamAt = text.indexOf('stream\n', imageAt);
  final header = text.substring(imageAt, streamAt);
  final width = int.parse(
    RegExp(r'/Width (\d+)').firstMatch(header)!.group(1)!,
  );
  final length = int.parse(
    RegExp(r'/Length (\d+)').firstMatch(header)!.group(1)!,
  );
  final start = streamAt + 'stream\n'.length;
  final rows = ZLibCodec().decode(bytes.sublist(start, start + length));
  final rowStart = y * (width * 3 + 1);
  expect(rows[rowStart], 0, reason: 'the encoder uses the None row filter');
  final pixelAt = rowStart + 1 + x * 3;
  return rows.sublist(pixelAt, pixelAt + 3);
}

void main() {
  testWidgets(
    'persisted handwriting survives capture, compression and PDF output',
    (tester) async {
      late BuildContext appContext;
      await tester.pumpWidget(
        testMaterialApp(
          home: Builder(
            builder: (context) {
              appContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.runAsync(() async {
        final db = AppDatabase(NativeDatabase.memory());
        final host = OffscreenCaptureHost(appContext);
        try {
          final repository = DriftAgendaRepository(db);
          final agenda = await repository.createAgenda(title: 'Con tinta');
          final page = (await repository.watchPages(agenda.id).first).single;
          await repository.insertStroke(
            InkStroke(
              id: 'red-pen',
              pageId: page.id,
              tool: InkToolType.pen,
              colorHex: '#FFFF0000',
              strokeWidth: 24,
              points: const [StrokePoint(100, 80), StrokePoint(300, 80)],
              createdAt: DateTime.utc(2026),
            ),
          );
          final service = PdfExportService(repository);
          for (final includeInk in [true, false]) {
            final result = await service.export(
              agendaId: agenda.id,
              options: ExportOptions(includeInk: includeInk),
              // Low resolution keeps this integration test light; the real
              // font wait, painter, native worker and PDF writer are unchanged.
              capture: (widget, _) => host.capture(widget, 0.25),
            );
            final file = File(result.artifact.path!);
            try {
              final bytes = await file.readAsBytes();
              expect(latin1.decode(bytes), contains('/Count 2'));
              final pixel = _pdfPixel(bytes, 1, 50, 20);
              if (includeInk) {
                expect(pixel, [255, 0, 0]);
              } else {
                expect(pixel, isNot([255, 0, 0]));
              }
            } finally {
              await file.delete();
            }
          }
        } finally {
          host.dispose();
          await db.close();
        }
      });
      expect(tester.takeException(), isNull);
    },
  );
}
