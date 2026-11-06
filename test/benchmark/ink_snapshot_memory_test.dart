@Tags(['benchmark'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/core/database/app_database.dart'
    hide Agenda, AgendaPage;
import 'package:honeyday/features/agendas/data/repositories/drift_agenda_repository.dart';

/// Compare modes in separate processes to avoid sharing a warmed heap:
/// --dart-define=honeyday.inkSnapshotMode=lazy (or eager/template).
const _mode = String.fromEnvironment(
  'honeyday.inkSnapshotMode',
  defaultValue: 'lazy',
);

void main() {
  test(
    'ink snapshot allocation sample (informational, no timing threshold)',
    () async {
      expect(['lazy', 'eager', 'template'], contains(_mode));
      const pageCount = 20;
      const strokesPerPage = 20;
      const pointsPerStroke = 250;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = DriftAgendaRepository(db);
      final agenda = await repository.createAgenda(title: 'Ink memory sample');
      final pages = [(await repository.watchPages(agenda.id).first).single];
      for (var page = 2; page <= pageCount; page++) {
        pages.add(
          await repository.createPage(agendaId: agenda.id, pageNumber: page),
        );
      }
      final points = jsonEncode([
        for (var point = 0; point < pointsPerStroke; point++)
          {'x': point.toDouble(), 'y': (point % 100).toDouble(), 'p': 0.5},
      ]);
      await db.batch((batch) {
        batch.insertAll(db.strokes, [
          for (final page in pages)
            for (var index = 0; index < strokesPerPage; index++)
              StrokesCompanion.insert(
                id: '${page.id}-$index',
                pageId: page.id,
                pointsJson: Value(points),
              ),
        ]);
      });

      final before = ProcessInfo.currentRss;
      var peak = before;
      final clock = Stopwatch()..start();
      final snapshot = (await repository.getAgendaSnapshot(
        agenda.id,
        // The dart-define selects a different value in the template run.
        // ignore: avoid_redundant_argument_values
        includeInk: _mode != 'template',
      ))!;
      final eager = _mode == 'eager'
          ? [for (final page in snapshot.pages) page.strokes.toList()]
          : null;
      peak = math.max(peak, ProcessInfo.currentRss);
      var decodedPoints = 0;
      var largestPage = 0;
      for (var index = 0; index < snapshot.pages.length; index++) {
        final strokes = eager?[index] ?? snapshot.pages[index].strokes.toList();
        final pagePoints = strokes.fold(
          0,
          (count, ink) => count + ink.points.length,
        );
        decodedPoints += pagePoints;
        largestPage = math.max(largestPage, pagePoints);
        peak = math.max(peak, ProcessInfo.currentRss);
      }
      clock.stop();
      const expectedPoints = _mode == 'template'
          ? 0
          : pageCount * strokesPerPage * pointsPerStroke;
      expect(decodedPoints, expectedPoints);
      final retainedGeometry = _mode == 'eager' ? decodedPoints : largestPage;
      // RSS includes the engine, SQLite, JSON temporaries and GC reservations;
      // this is an observation, never a portable assertion about heap size.
      // ignore: avoid_print
      print(
        'INK_SNAPSHOT mode=$_mode pages=$pageCount points=$decodedPoints '
        'retainedGeometryPoints=$retainedGeometry '
        'rssBeforeMiB=${(before / 1048576).toStringAsFixed(1)} '
        'sampledRssPeakMiB=${(peak / 1048576).toStringAsFixed(1)} '
        'elapsedMs=${clock.elapsedMilliseconds}',
      );
    },
  );
}
