import 'package:flutter/material.dart';
import 'package:honeyday/features/canvas/canvas_constants.dart';
import 'package:honeyday/features/canvas/domain/models/canvas_widget_data.dart';
import 'package:honeyday/features/canvas/presentation/widgets/page_surface.dart';
import 'package:honeyday/features/canvas/presentation/widgets/static_element_box.dart';

/// Pure, non-interactive composition of an agenda page: paper + elements.
///
/// What: Renders [PaperStyle] paper and every canvas element positioned via
/// [StaticElementBox], with no Scaffold, no gestures, no selection chrome,
/// no snap guides, no toolbar and no ink layer.
/// Why: Single rendering path shared by the future PDF export and other
/// static consumers (thumbnails, previews). The parent controls the final
/// size (e.g. `SizedBox(width: kDefaultPageWidth, height: kDefaultPageHeight, …)`);
/// for image capture the host wraps it in its own `RepaintBoundary`.
class StaticPageView extends StatelessWidget {
  /// Creates a static page composition for [paperStyle] and [elements].
  const StaticPageView({
    required this.paperStyle,
    super.key,
    this.elements = const [],
    this.elementBuilder,
    this.pageSize = const Size(kDefaultPageWidth, kDefaultPageHeight),
  });

  /// Paper texture pattern of the page (from `AgendaPage.backgroundStyle`).
  final PaperStyle paperStyle;

  /// Elements to render, in stack order (later = painted on top).
  final List<CanvasWidgetData> elements;

  /// Builds the widget for one element (same contract as
  /// `PageViewCanvas.elementBuilder`). Consumers render read-only content by
  /// calling `CatalogRegistry.buildWidget(context, widgetType:, elementId:,
  /// configJson:, isInteractive: false, onConfigChanged: (_) {})`.
  ///
  /// When null, each element renders as an empty box of its own size.
  final Widget Function(BuildContext context, CanvasWidgetData element)?
  elementBuilder;

  /// Logical page dimensions; must match the editor's canvas size.
  ///
  /// Informational only: the widget paints into the constraints its host
  /// gives it, so hosts size it with a `SizedBox` (or equivalent) instead.
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: PageSurface(paperStyle: paperStyle)),
        for (final element in elements)
          StaticElementBox(
            position: element.position,
            size: element.size,
            rotation: element.rotation,
            child:
                elementBuilder?.call(context, element) ??
                const SizedBox.expand(),
          ),
      ],
    );
  }
}
