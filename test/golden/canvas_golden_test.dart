import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/canvas/domain/canvas_mode.dart';
import 'package:honeyday/features/canvas/presentation/pages/page_view_canvas.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';

class _CustomCanvasModeNotifier extends CanvasModeNotifier {
  _CustomCanvasModeNotifier(this._initial);
  final CanvasMode _initial;

  @override
  CanvasMode build() => _initial;
}

void main() {
  group('PageViewCanvas Multi-Layer Golden Tests', () {
    unawaited(
      goldenTest(
        'PageViewCanvas renders in edit mode and writing mode',
        fileName: 'canvas_page_modes',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          children: [
            GoldenTestScenario(
              name: 'Edit Mode with Transformable Widgets',
              child: SizedBox(
                width: 400,
                height: 520,
                child: ProviderScope(
                  overrides: [
                    canvasModeProvider.overrideWith(
                      () => _CustomCanvasModeNotifier(CanvasMode.edit),
                    ),
                  ],
                  child: PageViewCanvas(
                    pageId: 'page-edit-1',
                    pageSize: const Size(400, 520),
                    showToolbar: false,
                    initialElements: const [
                      CanvasWidgetData(
                        id: 'widget-1',
                        pageId: 'page-edit-1',
                        widgetType: 'calendar_grid',
                        position: Offset(40, 60),
                        size: Size(320, 200),
                      ),
                      CanvasWidgetData(
                        id: 'widget-2',
                        pageId: 'page-edit-1',
                        widgetType: 'text_box',
                        position: Offset(40, 280),
                        size: Size(220, 140),
                      ),
                    ],
                    elementBuilder: (context, data) {
                      return CatalogRegistry.buildWidget(
                        context,
                        widgetType: data.widgetType,
                        elementId: data.id,
                        configJson: data.configJson,
                        isInteractive: false,
                        onConfigChanged: (_) {},
                      );
                    },
                  ),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Writing Mode with Grid Paper',
              child: SizedBox(
                width: 400,
                height: 520,
                child: ProviderScope(
                  overrides: [
                    canvasModeProvider.overrideWith(
                      () => _CustomCanvasModeNotifier(CanvasMode.writing),
                    ),
                  ],
                  child: PageViewCanvas(
                    pageId: 'page-writing-1',
                    paperStyle: PaperStyle.grid,
                    pageSize: const Size(400, 520),
                    showToolbar: false,
                    initialElements: const [
                      CanvasWidgetData(
                        id: 'widget-3',
                        pageId: 'page-writing-1',
                        widgetType: 'budget_calculator',
                        position: Offset(30, 50),
                        size: Size(340, 220),
                      ),
                    ],
                    elementBuilder: (context, data) {
                      return CatalogRegistry.buildWidget(
                        context,
                        widgetType: data.widgetType,
                        elementId: data.id,
                        configJson: data.configJson,
                        isInteractive: true,
                        onConfigChanged: (_) {},
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
}
