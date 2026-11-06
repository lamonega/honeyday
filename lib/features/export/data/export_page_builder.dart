import 'package:flutter/widgets.dart';
import 'package:honeyday/features/agendas/domain/models/agenda.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_snapshot.dart';
import 'package:honeyday/features/agendas/presentation/widgets/notebook_cover.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_page_view.dart';
import 'package:honeyday/features/catalog/domain/catalog_registry.dart';
import 'package:honeyday/features/export/domain/export_options.dart';

/// Design size of the notebook cover inside the capture box.
///
/// The cover art uses fixed-pixel decorations (ribbon, stitches, spine
/// edges) authored for card-sized boxes; rendering it at half the page and
/// letting [FittedBox] scale it ×2 keeps title and decorations proportional
/// on a full page. Same aspect ratio as the page (400/550 = 800/1100).
const Size kCoverDesignSize = Size(400, 550);

/// Read-only widget tree for the agenda cover, sized to fill the capture box.
///
/// What: Renders [NotebookCover] without its delete button at
/// [kCoverDesignSize], scaled to the full page via [FittedBox].
/// Why: The cover becomes PDF page 1 — same widget, same single source of
/// truth as the home screen card.
Widget buildExportCover(Agenda agenda) {
  return ClipRect(
    child: FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: kCoverDesignSize.width,
        height: kCoverDesignSize.height,
        child: NotebookCover(
          title: agenda.title,
          coverStyle: agenda.coverStyle,
        ),
      ),
    ),
  );
}

/// Read-only widget tree for one snapshot page.
///
/// What: A [StaticPageView] with the page's paper style and elements in
/// z-order, honoring typed-content and handwriting options.
/// Why: Paper, elements and ink reuse the reader's rendering primitives.
Widget buildExportPage(AgendaPageSnapshot snapshot, ExportOptions options) {
  final elements = [
    for (final element in snapshot.elements)
      resolveExportElement(element, options),
  ];
  return StaticPageView(
    paperStyle: PaperStyle.fromString(snapshot.page.backgroundStyle),
    elements: elements,
    strokes: options.includeInk
        ? snapshot.strokes.toList(growable: false)
        : const [],
    elementBuilder: _buildElement,
  );
}

/// Applies the export's content policy to one element.
///
/// With `includeTypedContent` off, the element's `configJson` is reset to its
/// definition's `initialConfigJson` (blank template). Unknown widget types
/// are kept as-is rather than dropped.
@visibleForTesting
CanvasWidgetData resolveExportElement(
  CanvasWidgetData element,
  ExportOptions options,
) {
  if (options.includeTypedContent) return element;
  final initialConfig = CatalogRegistry.getDefinition(element.widgetType)
      ?.initialConfigJson;
  if (initialConfig == null) return element;
  return element.copyWith(configJson: initialConfig);
}

/// Builds one element read-only, delegating to the catalog registry.
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
