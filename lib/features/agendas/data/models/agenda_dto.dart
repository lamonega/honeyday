import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' as db;
import 'package:honeyday/features/agendas/domain/models/agenda.dart';

/// Data Transfer Object mapping between Drift [db.Agenda] and domain [Agenda].
class AgendaDto {
  /// Constructs an [AgendaDto].
  const AgendaDto({
    required this.id,
    required this.title,
    required this.coverStyle,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Factory creating an [AgendaDto] from a Drift [db.Agenda] record.
  factory AgendaDto.fromDrift(db.Agenda row) {
    return AgendaDto(
      id: row.id,
      title: row.title,
      coverStyle: row.coverStyle,
      pageCount: row.pageCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }

  /// Factory creating an [AgendaDto] from a domain [Agenda] entity.
  factory AgendaDto.fromEntity(Agenda entity) {
    return AgendaDto(
      id: entity.id,
      title: entity.title,
      coverStyle: entity.coverStyle,
      pageCount: entity.pageCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
    );
  }

  /// Unique identifier of the agenda.
  final String id;

  /// User-facing title.
  final String title;

  /// Visual cover style.
  final String coverStyle;

  /// Number of pages.
  final int pageCount;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether soft-deleted.
  final bool isDeleted;

  /// Maps this DTO to a domain [Agenda] entity.
  Agenda toEntity() {
    return Agenda(
      id: id,
      title: title,
      coverStyle: coverStyle,
      pageCount: pageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  /// Maps this DTO to a Drift [db.AgendasCompanion] for inserts/updates.
  db.AgendasCompanion toCompanion() {
    return db.AgendasCompanion(
      id: Value(id),
      title: Value(title),
      coverStyle: Value(coverStyle),
      pageCount: Value(pageCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }
}
