import 'package:drift/drift.dart';
import 'package:honeyday/core/database/app_database.dart' as db;
import 'package:honeyday/features/agendas/domain/models/agenda_page.dart';

/// Data Transfer Object mapping between Drift [db.AgendaPage] and domain [AgendaPage].
class AgendaPageDto {
  /// Constructs an [AgendaPageDto].
  const AgendaPageDto({
    required this.id,
    required this.agendaId,
    required this.pageNumber,
    required this.backgroundStyle,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Factory creating an [AgendaPageDto] from a Drift [db.AgendaPage] record.
  factory AgendaPageDto.fromDrift(db.AgendaPage row) {
    return AgendaPageDto(
      id: row.id,
      agendaId: row.agendaId,
      pageNumber: row.pageNumber,
      backgroundStyle: row.backgroundStyle,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
    );
  }

  /// Factory creating an [AgendaPageDto] from a domain [AgendaPage] entity.
  factory AgendaPageDto.fromEntity(AgendaPage entity) {
    return AgendaPageDto(
      id: entity.id,
      agendaId: entity.agendaId,
      pageNumber: entity.pageNumber,
      backgroundStyle: entity.backgroundStyle,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
    );
  }

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

  /// Whether soft-deleted.
  final bool isDeleted;

  /// Maps this DTO to a domain [AgendaPage] entity.
  AgendaPage toEntity() {
    return AgendaPage(
      id: id,
      agendaId: agendaId,
      pageNumber: pageNumber,
      backgroundStyle: backgroundStyle,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  /// Maps this DTO to a Drift [db.PagesCompanion] for inserts/updates.
  db.PagesCompanion toCompanion() {
    return db.PagesCompanion(
      id: Value(id),
      agendaId: Value(agendaId),
      pageNumber: Value(pageNumber),
      backgroundStyle: Value(backgroundStyle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }
}
