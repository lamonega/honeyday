import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/canvas/domain/ink_tool.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/domain/models/ink_stroke.dart';
import 'package:honeyday/features/canvas/domain/models/stroke_point.dart';
import 'package:honeyday/features/export/data/export_page_builder.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

import '../helpers/l10n_wrapper.dart';

AgendaPageSnapshot _page() => AgendaPageSnapshot(
  page: AgendaPage(
    id: 'page',
    agendaId: 'agenda',
    pageNumber: 1,
    backgroundStyle: 'lined',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  elements: const [
    CanvasWidgetData(
      id: 'note',
      pageId: 'page',
      widgetType: 'text_box',
      position: Offset(60, 80),
      size: Size(680, 200),
      configJson: '{"text":"Mi cuaderno personal"}',
    ),
  ],
  strokes: [
    InkStroke(
      id: 'highlighter',
      pageId: 'page',
      tool: InkToolType.highlighter,
      colorHex: '#FFFBBF24',
      strokeWidth: 40,
      points: const [StrokePoint(80, 110), StrokePoint(420, 110)],
      createdAt: DateTime.utc(2026),
    ),
    InkStroke(
      id: 'pen',
      pageId: 'page',
      tool: InkToolType.pen,
      colorHex: '#FF2563EB',
      strokeWidth: 8,
      points: const [
        StrokePoint(100, 450, 0.4),
        StrokePoint(130, 350, 0.6),
        StrokePoint(180, 430, 0.5),
        StrokePoint(230, 350, 0.8),
        StrokePoint(270, 450, 0.4),
        StrokePoint(300, 410, 0.7),
        StrokePoint(370, 430, 0.6),
        StrokePoint(430, 350, 0.5),
        StrokePoint(450, 450, 0.8),
      ],
      createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
    ),
  ],
);

Widget _preview(ExportOptions options) => SizedBox(
  width: 320,
  height: 440,
  child: FittedBox(
    child: SizedBox(
      width: 800,
      height: 1100,
      child: buildExportPage(_page(), options),
    ),
  ),
);

void main() {
  unawaited(
    goldenTest(
      'PDF distinguishes complete agenda from reusable template',
      fileName: 'export_ink_modes',
      builder: () => TestL10n(
        child: GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(
            maxWidth: 340,
            maxHeight: 480,
          ),
          children: [
            GoldenTestScenario(
              name: 'Agenda',
              child: _preview(const ExportOptions()),
            ),
            GoldenTestScenario(
              name: 'Plantilla',
              child: _preview(
                const ExportOptions(
                  includeTypedContent: false,
                  includeInk: false,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
