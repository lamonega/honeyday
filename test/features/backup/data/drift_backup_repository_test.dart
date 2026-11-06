import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';
import 'package:honeyday/features/backup/data/backup_document.dart';
import 'package:honeyday/features/backup/data/drift_backup_repository.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';

void main() {
  late AppDatabase source;
  late AppDatabase target;
  late DriftAgendaRepository agendas;
  late DriftBackupRepository exporter;
  late DriftBackupRepository importer;

  late bool previousMultipleDatabaseWarning;
  setUp(() {
    // These are independent in-memory executors, not duplicate connections.
    previousMultipleDatabaseWarning =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    agendas = DriftAgendaRepository(source);
    exporter = DriftBackupRepository(source);
    importer = DriftBackupRepository(target);
  });

  tearDown(() async {
    await source.close();
    await target.close();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases =
        previousMultipleDatabaseWarning;
  });

  Future<Uint8List> populatedBackup() async {
    final agenda = await agendas.createAgenda(
      title: 'Mi diario 🐝',
      coverStyle: 'sage',
    );
    final first = (await agendas.watchPages(agenda.id).first).single;
    final second = await agendas.createPage(
      agendaId: agenda.id,
      pageNumber: 2,
      backgroundStyle: 'lined',
    );
    await agendas.reorderPages([second.id, first.id]);
    await agendas.upsertCanvasElement(
      CanvasWidgetData(
        id: 'element',
        pageId: first.id,
        widgetType: 'future_widget',
        position: const Offset(-12.5, 25),
        size: const Size(300, 80),
        rotation: 0.7,
        configJson: r'{"text":"ideas\nmañana","custom":{"enabled":true}}',
      ),
    );
    await agendas.insertStroke(
      InkStroke(
        id: 'stroke',
        pageId: first.id,
        tool: InkToolType.highlighter,
        colorHex: '#80FFD977',
        strokeWidth: 9,
        points: [const StrokePoint(1.2, 3.4, 0.75), const StrokePoint(8, 9)],
        createdAt: DateTime.utc(2026, 10),
      ),
    );
    return await exporter.exportBackup();
  }

  test('an empty library produces a valid empty backup', () async {
    final bytes = await exporter.exportBackup();
    expect(importer.inspectBackup(bytes).agendas, 0);
    expect(await importer.restoreBackup(bytes), 0);
    expect(await target.select(target.agendas).get(), isEmpty);
  });

  test('round trips editable content, ink, metadata and page order', () async {
    final bytes = await populatedBackup();
    final summary = importer.inspectBackup(bytes);
    expect(summary.agendas, 1);
    expect(summary.pages, 2);
    expect(summary.elements, 1);
    expect(summary.strokes, 1);

    expect(await importer.restoreBackup(bytes), 1);
    final restored = BackupDocument.decode(await importer.exportBackup());
    final original = BackupDocument.decode(bytes);
    final agenda = restored.agendas.single;
    expect(agenda.agenda.title, 'Mi diario 🐝');
    expect(agenda.agenda.coverStyle, 'sage');
    expect(agenda.agenda.pageCount, 2);
    expect(agenda.agenda.createdAt, original.agendas.single.agenda.createdAt);
    expect(agenda.agenda.updatedAt, original.agendas.single.agenda.updatedAt);
    expect(agenda.pages.map((p) => p.page.backgroundStyle), [
      'lined',
      'dotted',
    ]);
    final page = agenda.pages.last;
    final element = page.elements.single;
    expect(element.widgetType, 'future_widget');
    expect(element.posX, -12.5);
    expect(element.posY, 25);
    expect(element.width, 300);
    expect(element.height, 80);
    expect(element.rotation, 0.7);
    expect(
      element.configJson,
      original.agendas.single.pages.last.elements.single.configJson,
    );
    expect(element.pageId, page.page.id);
    final stroke = page.strokes.single;
    expect(stroke.brushType, 'highlighter');
    expect(stroke.colorHex, '#80FFD977');
    expect(stroke.strokeWidth, 9);
    expect(
      stroke.pointsJson,
      original.agendas.single.pages.last.strokes.single.pointsJson,
    );
    expect(stroke.createdAt, DateTime.utc(2026, 10));
    expect(stroke.pageId, page.page.id);
    expect(page.page.agendaId, agenda.agenda.id);

    final old = original.agendas.single;
    expect(agenda.agenda.id, isNot(old.agenda.id));
    expect(page.page.id, isNot(old.pages.last.page.id));
    expect(element.id, isNot(old.pages.last.elements.single.id));
    expect(stroke.id, isNot(old.pages.last.strokes.single.id));
  });

  test(
    'repeated imports create copies without changing existing data',
    () async {
      final bytes = await populatedBackup();
      final existing = DriftAgendaRepository(target);
      final original = await existing.createAgenda(title: 'Keep me');
      await importer.restoreBackup(bytes);
      await importer.restoreBackup(bytes);
      final all = await existing.watchAgendas().first;
      expect(all, hasLength(3));
      expect(all.map((a) => a.id).toSet(), hasLength(3));
      expect((await existing.getAgenda(original.id))!.title, 'Keep me');
      expect(await target.select(target.pages).get(), hasLength(5));
    },
  );

  test(
    'excludes deleted agendas, pages and elements and their descendants',
    () async {
      await populatedBackup();
      final agenda = (await agendas.watchAgendas().first).single;
      final pages = await agendas.watchPages(agenda.id).first;
      await agendas.deletePage(pages.last.id);
      final deletedAgenda = await agendas.createAgenda(title: 'Deleted');
      await agendas.deleteAgenda(deletedAgenda.id);
      await agendas.upsertCanvasElement(
        CanvasWidgetData(
          id: 'deleted',
          pageId: pages.first.id,
          widgetType: 'text_box',
          position: Offset.zero,
          size: const Size(20, 20),
        ),
      );
      await agendas.deleteCanvasElement('deleted');

      final summary = importer.inspectBackup(await exporter.exportBackup());
      expect(summary.agendas, 1);
      expect(summary.pages, 1);
      expect(summary.elements, 0);
      expect(summary.strokes, 0);
    },
  );

  test('rolls back every inserted row when a database write fails', () async {
    final bytes = await populatedBackup();
    await target.customStatement('''
      CREATE TRIGGER reject_ink BEFORE INSERT ON strokes
      BEGIN SELECT RAISE(ABORT, 'simulated disk failure'); END
    ''');

    await expectLater(importer.restoreBackup(bytes), throwsA(isA<Exception>()));
    expect(await target.select(target.agendas).get(), isEmpty);
    expect(await target.select(target.pages).get(), isEmpty);
    expect(await target.select(target.canvasElements).get(), isEmpty);
    expect(await target.select(target.strokes).get(), isEmpty);
  });

  test('rejects oversized input before decoding', () {
    final bytes = Uint8List(BackupDocument.maxBytes + 1);
    expect(() => importer.inspectBackup(bytes), throwsFormatException);
  });

  test('rejects invalid UTF-8 and malformed JSON', () {
    for (final bytes in [
      Uint8List.fromList([255]),
      Uint8List.fromList(utf8.encode('{')),
    ]) {
      expect(() => importer.inspectBackup(bytes), throwsFormatException);
    }
  });

  final invalidMutations = <String, void Function(Map<String, dynamic>)>{
    'unknown format': (j) => j['format'] = 'something else',
    'future version': (j) => j['version'] = 2,
    'non integer version': (j) => j['version'] = 1.0,
    'deleted agenda': (j) => _agenda(j)['isDeleted'] = true,
    'missing agendas': (j) => j.remove('agendas'),
    'invalid date': (j) => _agenda(j)['createdAt'] = 'yesterday',
    'non UTC date': (j) => _agenda(j)['updatedAt'] = '2026-01-01',
    'duplicate agenda ids': (j) => (j['agendas'] as List<dynamic>).add(
      (j['agendas'] as List<dynamic>).first,
    ),
    'agenda with no pages': (j) => _entry(j)['pages'] = <dynamic>[],
    'duplicate page numbers': (j) => _page(j)['pageNumber'] = 1,
    'duplicate page ids': (j) => _page(j)['id'] =
        (((_entry(j)['pages'] as List<dynamic>).first
                as Map<String, dynamic>)['page']
            as Map<String, dynamic>)['id'],
    'wrong parent': (j) => _page(j)['agendaId'] = 'other agenda',
    'deleted page': (j) => _page(j)['isDeleted'] = true,
    'invalid position': (j) => _element(j)['posX'] = 'ten',
    'non finite position': (j) =>
        _element(j)['posX'] = 1e300, // replaced with overflow JSON below
    'zero width': (j) => _element(j)['width'] = 0,
    'negative height': (j) => _element(j)['height'] = -1,
    'invalid config JSON': (j) => _element(j)['configJson'] = '{broken',
    'non object config': (j) => _element(j)['configJson'] = '[]',
    'wrong stroke parent': (j) => _stroke(j)['pageId'] = 'other page',
    'invalid brush': (j) => _stroke(j)['brushType'] = 'unknown',
    'invalid color': (j) => _stroke(j)['colorHex'] = '#oops',
    'invalid stroke width': (j) => _stroke(j)['strokeWidth'] = -1,
    'invalid points': (j) => _stroke(j)['pointsJson'] = '[{"x":1,"y":"bad"}]',
    'invalid pressure': (j) =>
        _stroke(j)['pointsJson'] = '[{"x":1,"y":2,"p":"bad"}]',
  };
  for (final mutation in invalidMutations.entries) {
    test('rejects ${mutation.key} without writing anything', () async {
      final json = jsonDecode(
        utf8.decode(await populatedBackup()),
      ) as Map<String, dynamic>;
      mutation.value(json);
      var text = jsonEncode(json);
      if (mutation.key == 'non finite position') {
        text = text.replaceAll('1e+300', '1e999');
      }
      final bytes = Uint8List.fromList(utf8.encode(text));
      expect(() => importer.inspectBackup(bytes), throwsFormatException);
      await expectLater(importer.restoreBackup(bytes), throwsFormatException);
      expect(await target.select(target.agendas).get(), isEmpty);
    });
  }
}

Map<String, dynamic> _entry(Map<String, dynamic> json) =>
    (json['agendas'] as List<dynamic>).first as Map<String, dynamic>;
Map<String, dynamic> _agenda(Map<String, dynamic> json) =>
    _entry(json)['agenda'] as Map<String, dynamic>;
Map<String, dynamic> _pageEntry(Map<String, dynamic> json) =>
    (_entry(json)['pages'] as List<dynamic>).last as Map<String, dynamic>;
Map<String, dynamic> _page(Map<String, dynamic> json) =>
    _pageEntry(json)['page'] as Map<String, dynamic>;
Map<String, dynamic> _element(Map<String, dynamic> json) =>
    (_pageEntry(json)['elements'] as List<dynamic>).single
        as Map<String, dynamic>;
Map<String, dynamic> _stroke(Map<String, dynamic> json) =>
    (_pageEntry(json)['strokes'] as List<dynamic>).single
        as Map<String, dynamic>;
