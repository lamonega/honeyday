import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/domain/repositories/repository_interfaces.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';
import 'package:honeyday/features/export/data/pdf_export_service.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

/// 1×1 transparent PNG used as a stand-in for a captured page.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Minimal repository stub: only `getAgendaSnapshot` is exercised.
class _FakeRepository implements FullAgendaRepository {
  _FakeRepository(this.snapshot);

  final AgendaSnapshot? snapshot;

  @override
  Future<AgendaSnapshot?> getAgendaSnapshot(String agendaId) async => snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AgendaSnapshot buildSnapshot({String title = 'Mi agenda', int pageCount = 1}) {
  final now = DateTime(2026);
  final agenda = Agenda(
    id: 'a1',
    title: title,
    coverStyle: 'honey',
    pageCount: pageCount,
    createdAt: now,
    updatedAt: now,
  );
  final pages = [
    for (var i = 1; i <= pageCount; i++)
      AgendaPageSnapshot(
        page: AgendaPage(
          id: 'p$i',
          agendaId: 'a1',
          pageNumber: i,
          backgroundStyle: 'blank',
          createdAt: now,
          updatedAt: now,
        ),
        elements: const [],
      ),
  ];
  return AgendaSnapshot(agenda: agenda, pages: pages);
}

void main() {
  test('captures the cover first, then every page, and builds the PDF', () async {
    final service = PdfExportService(
      _FakeRepository(buildSnapshot(pageCount: 2)),
    );
    final captured = <Widget>[];
    final ratios = <double>[];
    final progress = <(int, int)>[];

    final result = await service.export(
      agendaId: 'a1',
      options: const ExportOptions(),
      capture: (page, pixelRatio) async {
        captured.add(page);
        ratios.add(pixelRatio);
        return tinyPng;
      },
      onProgress: (completed, total) => progress.add((completed, total)),
    );

    expect(captured, hasLength(3));
    expect(progress, [(1, 3), (2, 3), (3, 3)]);
    expect(latin1.decode(result.bytes), startsWith('%PDF'));
    expect(result.fileName, 'Mi agenda — Honeyday.pdf');

    // First capture is the cover: FittedBox at design size over NotebookCover.
    final cover = (captured.first as ClipRect).child! as FittedBox;
    expect((cover.child! as SizedBox).child, isA<NotebookCover>());

    // A4 at 300 dpi ⇒ pixelRatio ≈ 3.10 on every capture.
    expect(ratios, everyElement(closeTo(3.1, 0.01)));
  });

  test('throws ExportCancelled between pages when the user cancels', () async {
    var cancelled = false;
    var captures = 0;
    final service = PdfExportService(_FakeRepository(buildSnapshot()));

    await expectLater(
      service.export(
        agendaId: 'a1',
        options: const ExportOptions(),
        capture: (page, pixelRatio) async {
          captures++;
          cancelled = true; // cancel right after the first capture
          return tinyPng;
        },
        isCancelled: () => cancelled,
      ),
      throwsA(isA<ExportCancelled>()),
    );

    expect(captures, 1); // cover captured, page never started
  });

  test('throws StateError when the agenda does not exist', () async {
    final service = PdfExportService(_FakeRepository(null));

    await expectLater(
      service.export(
        agendaId: 'missing',
        options: const ExportOptions(),
        capture: (page, pixelRatio) async => tinyPng,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
