import 'package:flutter/material.dart';
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';
import 'package:honeyday/features/agendas/presentation/widgets/add_catalog_element_sheet.dart';
import 'package:honeyday/features/agendas/presentation/widgets/new_page_dialog.dart';
import 'package:honeyday/features/agendas/presentation/widgets/page_manager_sheet.dart';
import 'package:honeyday/features/catalog/domain/agenda_widget_definition.dart';

/// Wraps catalog-related bottom-sheet and dialog presentation for the viewer.
///
/// Each static method opens a modal and returns the user's selection.
/// The caller is responsible for reacting to the returned value.
class ViewerCatalogSheet {
  const ViewerCatalogSheet._();

  /// Shows the page-manager bottom sheet for managing agenda pages.
  static Future<void> showPageManager({
    required BuildContext context,
    required List<AgendaPage> pages,
    required int currentPageIndex,
    required ValueChanged<int> onSelectPage,
    required ValueChanged<String> onDeletePage,
    required void Function(String pageId, String style) onChangePaperStyle,
    required ValueChanged<List<String>> onReorderPages,
    required VoidCallback onAddPage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PageManagerSheet(
        pages: pages,
        currentPageIndex: currentPageIndex,
        onSelectPage: onSelectPage,
        onDeletePage: onDeletePage,
        onChangePaperStyle: onChangePaperStyle,
        onReorderPages: onReorderPages,
        onAddPage: onAddPage,
      ),
    );
  }

  /// Shows the new-page design dialog and returns the selected paper style key.
  static Future<String?> showNewPageDesign(BuildContext context) {
    return showNewPageDesignDialog(context);
  }

  /// Shows the catalog element picker and returns the selected definition.
  static Future<AgendaWidgetDefinition?> showElementPicker(
    BuildContext context,
  ) {
    return AddCatalogElementSheet.show(context);
  }
}
