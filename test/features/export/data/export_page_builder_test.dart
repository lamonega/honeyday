import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:honeyday/features/export/data/export_page_builder.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

void main() {
  CanvasWidgetData elementWithConfig(String configJson) {
    return CanvasWidgetData(
      id: 'e1',
      pageId: 'p1',
      widgetType: 'text_box',
      position: Offset.zero,
      size: const Size(200, 100),
      configJson: configJson,
    );
  }

  group('resolveExportElement', () {
    test('keeps the element untouched when typed content is included', () {
      // includeTypedContent defaults to true — that default is the contract.
      const options = ExportOptions();
      final element = elementWithConfig('{"text":"hola"}');

      final resolved = resolveExportElement(element, options);

      expect(identical(resolved, element), isTrue);
      expect(resolved.configJson, '{"text":"hola"}');
    });

    test('resets configJson to the definition default for blank exports', () {
      const options = ExportOptions(includeTypedContent: false);
      final element = elementWithConfig('{"text":"hola"}');
      final initialConfig = CatalogRegistry.getDefinition('text_box')!
          .initialConfigJson;

      final resolved = resolveExportElement(element, options);

      expect(resolved.configJson, initialConfig);
      expect(resolved.id, element.id);
      expect(resolved.position, element.position);
      expect(resolved.size, element.size);
    });

    test('keeps unknown widget types as-is instead of dropping them', () {
      const options = ExportOptions(includeTypedContent: false);
      const element = CanvasWidgetData(
        id: 'e2',
        pageId: 'p1',
        widgetType: 'not_a_registered_type',
        position: Offset.zero,
        size: Size(50, 50),
        configJson: '{"keep":"me"}',
      );

      final resolved = resolveExportElement(element, options);

      expect(resolved.configJson, '{"keep":"me"}');
    });
  });

  group('buildExportCover', () {
    test(
      'renders the notebook cover without a delete button at design size',
      () {
        final cover = buildExportCover(
          Agenda(
            id: 'a1',
            title: 'Mi agenda',
            coverStyle: 'honey',
            pageCount: 1,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );

        expect(cover, isA<ClipRect>());
        final fitted = (cover as ClipRect).child! as FittedBox;
        final sized = fitted.child! as SizedBox;
        expect(sized.width, kCoverDesignSize.width);
        expect(sized.height, kCoverDesignSize.height);
        expect(sized.child, isA<NotebookCover>());
      },
    );
  });
}
