import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_page_view.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

import '../helpers/l10n_wrapper.dart';

/// Read-only catalog rendering, as a static consumer (export/thumbnails)
/// would wire it.
Widget _buildElement(BuildContext context, CanvasWidgetData element) {
  return CatalogRegistry.buildWidget(
    context,
    widgetType: element.widgetType,
    elementId: element.id,
    configJson: element.configJson,
    isInteractive: false,
    onConfigChanged: (_) {},
  );
}

void main() {
  group('StaticPageView Golden Tests', () {
    unawaited(
      goldenTest(
        'StaticPageView renders paper and elements without viewer chrome',
        fileName: 'static_page_view',
        builder: () => TestL10n(
          child: GoldenTestGroup(
            scenarioConstraints: const BoxConstraints(
              maxWidth: 420,
              maxHeight: 560,
            ),
            children: [
              GoldenTestScenario(
                name: 'Empty dotted page',
                child: const SizedBox(
                  width: 400,
                  height: 520,
                  child: StaticPageView(
                    paperStyle: PaperStyle.dotted,
                    elementBuilder: _buildElement,
                  ),
                ),
              ),
              GoldenTestScenario(
                name: 'Lined page with box, text note, and rotated pill',
                child: const SizedBox(
                  width: 400,
                  height: 520,
                  child: StaticPageView(
                    paperStyle: PaperStyle.lined,
                    elements: [
                      CanvasWidgetData(
                        id: 'elem-box-1',
                        pageId: 'page-static-2',
                        widgetType: 'shape_box',
                        position: Offset(52, 64),
                        size: Size(200, 120),
                      ),
                      CanvasWidgetData(
                        id: 'elem-note-1',
                        pageId: 'page-static-2',
                        widgetType: 'text_box',
                        position: Offset(120, 236),
                        size: Size(210, 150),
                        configJson:
                            '{"text":"Recordar la reuni\u00f3n del lunes","color":"rose","fontSize":14}',
                      ),
                      CanvasWidgetData(
                        id: 'elem-rot-1',
                        pageId: 'page-static-2',
                        widgetType: 'shape_pill',
                        position: Offset(88, 412),
                        size: Size(170, 44),
                        rotation: 0.28,
                      ),
                    ],
                    elementBuilder: _buildElement,
                  ),
                ),
              ),
              GoldenTestScenario(
                name: 'Grid page with element crossing the margin',
                child: const SizedBox(
                  width: 400,
                  height: 520,
                  child: StaticPageView(
                    paperStyle: PaperStyle.grid,
                    elements: [
                      CanvasWidgetData(
                        id: 'elem-margin-1',
                        pageId: 'page-static-3',
                        widgetType: 'planner_sticky_note',
                        position: Offset(8, 300),
                        size: Size(240, 180),
                      ),
                    ],
                    elementBuilder: _buildElement,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
}
