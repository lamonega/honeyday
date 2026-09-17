/// Pure Dart domain model representing an Agenda.
class Agenda {
  /// Constructs an [Agenda].
  const Agenda({
    required this.id,
    required this.title,
    required this.coverStyle,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Unique identifier of the agenda.
  final String id;

  /// User-facing title.
  final String title;

  /// Visual cover style identifier.
  final String coverStyle;

  /// Total number of pages in the agenda.
  final int pageCount;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Whether the agenda has been soft-deleted.
  final bool isDeleted;

  /// Returns a copy of this [Agenda] with updated fields.
  Agenda copyWith({
    String? id,
    String? title,
    String? coverStyle,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Agenda(
      id: id ?? this.id,
      title: title ?? this.title,
      coverStyle: coverStyle ?? this.coverStyle,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
