import 'dart:convert';
import 'dart:typed_data';

import 'package:honeyday/core/database/app_database.dart';
import 'package:honeyday/features/backup/domain/backup_repository.dart';

/// Versioned JSON DTO. Dates are UTC ISO-8601, not Drift's default epoch units.
/// Unknown widget types/config fields survive a round trip unchanged.
class BackupDocument {
  const BackupDocument(this.agendas);

  factory BackupDocument.decode(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup exceeds the 50 MiB limit.');
    }
    final root = _object(jsonDecode(utf8.decode(bytes)));
    if (root['format'] != 'honeyday-backup' ||
        root['version'] is! int ||
        root['version'] != 1) {
      throw const FormatException('Not a supported Honeyday backup.');
    }
    _date(root, 'exportedAt');
    final agendaIds = <String>{};
    final pageIds = <String>{};
    final elementIds = <String>{};
    final strokeIds = <String>{};
    final agendas = <BackupAgenda>[];
    for (final value in _list(root, 'agendas')) {
      final entry = _object(value);
      final data = _object(entry['agenda']);
      final id = _uniqueId(data, agendaIds);
      if (data['isDeleted'] != false) {
        throw const FormatException('Deleted agendas are not supported.');
      }
      final pages = <BackupPage>[];
      final pageNumbers = <int>{};
      for (final pageValue in _list(entry, 'pages')) {
        final pageEntry = _object(pageValue);
        final pageData = _object(pageEntry['page']);
        final pageId = _uniqueId(pageData, pageIds);
        _parent(pageData, 'agendaId', id);
        final number = _positiveInt(pageData, 'pageNumber');
        if (!pageNumbers.add(number)) {
          throw const FormatException('Duplicate page number.');
        }
        final elements = <CanvasElement>[];
        for (final elementValue in _list(pageEntry, 'elements')) {
          final element = _object(elementValue);
          final elementId = _uniqueId(element, elementIds);
          _parent(element, 'pageId', pageId);
          final config = _text(element, 'configJson');
          _object(jsonDecode(config));
          elements.add(
            CanvasElement(
              id: elementId,
              pageId: pageId,
              widgetType: _text(element, 'widgetType', nonEmpty: true),
              posX: _number(element, 'posX'),
              posY: _number(element, 'posY'),
              width: _number(element, 'width', positive: true),
              height: _number(element, 'height', positive: true),
              rotation: _number(element, 'rotation'),
              configJson: config,
              createdAt: _date(element, 'createdAt'),
              updatedAt: _date(element, 'updatedAt'),
              isDeleted: false,
            ),
          );
        }
        final strokes = <Stroke>[];
        for (final strokeValue in _list(pageEntry, 'strokes')) {
          final stroke = _object(strokeValue);
          final strokeId = _uniqueId(stroke, strokeIds);
          _parent(stroke, 'pageId', pageId);
          final brush = _text(stroke, 'brushType');
          final color = _text(stroke, 'colorHex');
          if (!{'pen', 'highlighter', 'eraser'}.contains(brush) ||
              !RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(color)) {
            throw const FormatException('Invalid stroke brush or color.');
          }
          final pointsJson = _text(stroke, 'pointsJson');
          final points = jsonDecode(pointsJson);
          if (points is! List<dynamic>) {
            throw const FormatException('Expected stroke points.');
          }
          for (final pointValue in points) {
            final point = _object(pointValue);
            _number(point, 'x');
            _number(point, 'y');
            if (point['p'] != null) _number(point, 'p');
          }
          strokes.add(
            Stroke(
              id: strokeId,
              pageId: pageId,
              brushType: brush,
              colorHex: color,
              strokeWidth: _number(stroke, 'strokeWidth', positive: true),
              pointsJson: pointsJson,
              createdAt: _date(stroke, 'createdAt'),
              updatedAt: _date(stroke, 'updatedAt'),
              isDeleted: false,
            ),
          );
        }
        pages.add(
          BackupPage(
            Page(
              id: pageId,
              agendaId: id,
              pageNumber: number,
              backgroundStyle: _text(
                pageData,
                'backgroundStyle',
                nonEmpty: true,
              ),
              createdAt: _date(pageData, 'createdAt'),
              updatedAt: _date(pageData, 'updatedAt'),
              isDeleted: false,
            ),
            elements,
            strokes,
          ),
        );
      }
      if (pages.isEmpty) {
        throw const FormatException(
          'An agenda must contain at least one page.',
        );
      }
      pages.sort((a, b) => a.page.pageNumber.compareTo(b.page.pageNumber));
      agendas.add(
        BackupAgenda(
          Agenda(
            id: id,
            title: _text(data, 'title'),
            coverStyle: _text(data, 'coverStyle', nonEmpty: true),
            pageCount: pages.length,
            createdAt: _date(data, 'createdAt'),
            updatedAt: _date(data, 'updatedAt'),
            isDeleted: false,
          ),
          pages,
        ),
      );
    }
    return BackupDocument(agendas);
  }

  static const int maxBytes = 50 * 1024 * 1024;
  final List<BackupAgenda> agendas;

  BackupSummary get summary => BackupSummary(
    agendas: agendas.length,
    pages: agendas.fold(0, (total, a) => total + a.pages.length),
    elements: agendas.fold(
      0,
      (total, a) =>
          total + a.pages.fold(0, (sum, p) => sum + p.elements.length),
    ),
    strokes: agendas.fold(
      0,
      (total, a) => total + a.pages.fold(0, (sum, p) => sum + p.strokes.length),
    ),
  );

  Uint8List encode() {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'honeyday-backup',
          'version': 1,
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'agendas': [
            for (final entry in agendas)
              {
                'agenda': _withDates(
                  entry.agenda.toJson(),
                  entry.agenda.createdAt,
                  entry.agenda.updatedAt,
                ),
                'pages': [
                  for (final p in entry.pages)
                    {
                      'page': _withDates(
                        p.page.toJson(),
                        p.page.createdAt,
                        p.page.updatedAt,
                      ),
                      'elements': [
                        for (final e in p.elements)
                          _withDates(e.toJson(), e.createdAt, e.updatedAt),
                      ],
                      'strokes': [
                        for (final s in p.strokes)
                          _withDates(s.toJson(), s.createdAt, s.updatedAt),
                      ],
                    },
                ],
              },
          ],
        }),
      ),
    );
    if (bytes.length > maxBytes) {
      throw const FormatException('Backup exceeds the 50 MiB limit.');
    }
    return bytes;
  }
}

class BackupAgenda {
  const BackupAgenda(this.agenda, this.pages);
  final Agenda agenda;
  final List<BackupPage> pages;
}

class BackupPage {
  const BackupPage(this.page, this.elements, this.strokes);
  final Page page;
  final List<CanvasElement> elements;
  final List<Stroke> strokes;
}

Map<String, dynamic> _withDates(
  Map<String, dynamic> json,
  DateTime created,
  DateTime updated,
) => {
  ...json,
  'createdAt': created.toUtc().toIso8601String(),
  'updatedAt': updated.toUtc().toIso8601String(),
};

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List<dynamic>) {
    throw FormatException('Expected a list: $key.');
  }
  return value;
}

String _text(Map<String, dynamic> json, String key, {bool nonEmpty = false}) {
  final value = json[key];
  if (value is! String || (nonEmpty && value.trim().isEmpty)) {
    throw FormatException('Invalid text: $key.');
  }
  return value;
}

String _uniqueId(Map<String, dynamic> json, Set<String> ids) {
  final id = _text(json, 'id', nonEmpty: true);
  if (!ids.add(id)) throw const FormatException('Duplicate identifier.');
  return id;
}

void _parent(Map<String, dynamic> json, String key, String expected) {
  if (_text(json, key) != expected || json['isDeleted'] != false) {
    throw const FormatException('Invalid parent or deleted content.');
  }
}

double _number(Map<String, dynamic> json, String key, {bool positive = false}) {
  final value = json[key];
  if (value is! num || !value.toDouble().isFinite || (positive && value <= 0)) {
    throw FormatException('Invalid number: $key.');
  }
  return value.toDouble();
}

int _positiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw FormatException('Invalid integer: $key.');
  }
  return value;
}

DateTime _date(Map<String, dynamic> json, String key) {
  final value = DateTime.tryParse(_text(json, key));
  if (value == null || !value.isUtc) {
    throw FormatException('Expected a UTC ISO-8601 date: $key.');
  }
  return value;
}
