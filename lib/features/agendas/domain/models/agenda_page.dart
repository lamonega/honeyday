/// Pure Dart domain model representing a page within an agenda.
class AgendaPage {
  /// Constructs an [AgendaPage].
  const AgendaPage({
    required this.id,
    required this.agendaId,
    required this.pageNumber,
    required this.backgroundStyle,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Unique identifier of the page.
  final String id;

  /// Parent agenda identifier.
  final String agendaId;

  /// 1-based page order number.
  final int pageNumber;

  /// Visual paper texture or grid style.
  final String backgroundStyle;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Whether the page has been soft-deleted.
  final bool isDeleted;

  /// Returns a copy of this [AgendaPage] with updated fields.
  AgendaPage copyWith({
    String? id,
    String? agendaId,
    int? pageNumber,
    String? backgroundStyle,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return AgendaPage(
      id: id ?? this.id,
      agendaId: agendaId ?? this.agendaId,
      pageNumber: pageNumber ?? this.pageNumber,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
