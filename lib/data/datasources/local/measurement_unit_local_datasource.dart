import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/measurement_unit.dart' as entity;
import '../../../domain/models/paginated_result.dart';
import '../../../core/services/audit_service.dart';

abstract class MeasurementUnitLocalDataSource {
  Future<List<entity.MeasurementUnit>> getAll({String? userId});
  Future<PaginatedResult<entity.MeasurementUnit>> getPaginated({
    required int page,
    required int pageSize,
    String? userId,
  });
  Future<int> getCount({String? userId});
  Future<entity.MeasurementUnit?> getById(String id);
  Future<void> insert(entity.MeasurementUnit measurementUnit);
  Future<void> update(entity.MeasurementUnit measurementUnit);
  Future<void> upsert(entity.MeasurementUnit measurementUnit);
  Future<void> upsertAll(List<entity.MeasurementUnit> measurementUnits);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<List<entity.MeasurementUnit>> getUnsyncedItems();
  Future<void> markAsSynced(String id);
}

class MeasurementUnitLocalDataSourceImpl implements MeasurementUnitLocalDataSource {
  final AppDatabase database;
  late final AuditService auditService;

  MeasurementUnitLocalDataSourceImpl({required this.database}) {
    auditService = AuditService(database: database);
  }

  @override
  Future<List<entity.MeasurementUnit>> getAll({String? userId}) async {
    var query = database.select(database.measurementUnits);

    if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    final items = await query.get();
    return items
        .map((item) => entity.MeasurementUnit(
              id: item.id,
              userId: item.userId,
              name: item.name,
              acronym: item.acronym,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
            ))
        .toList();
  }

  @override
  Future<PaginatedResult<entity.MeasurementUnit>> getPaginated({
    required int page,
    required int pageSize,
    String? userId,
  }) async {
    var query = database.select(database.measurementUnits);

    if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    final totalCount = await getCount(userId: userId);
    final offset = (page - 1) * pageSize;

    query = query
      ..limit(pageSize, offset: offset)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final items = await query.get();
    final measurementUnits = items
        .map((item) => entity.MeasurementUnit(
              id: item.id,
              userId: item.userId,
              name: item.name,
              acronym: item.acronym,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
            ))
        .toList();

    return PaginatedResult(
      items: measurementUnits,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  @override
  Future<int> getCount({String? userId}) async {
    var query = database.selectOnly(database.measurementUnits)
      ..addColumns([database.measurementUnits.id.count()]);

    if (userId != null) {
      query = query..where(database.measurementUnits.userId.equals(userId));
    }

    final result = await query.getSingle();
    return result.read(database.measurementUnits.id.count()) ?? 0;
  }

  @override
  Future<entity.MeasurementUnit?> getById(String id) async {
    final item = await (database.select(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;

    return entity.MeasurementUnit(
      id: item.id,
      userId: item.userId,
      name: item.name,
      acronym: item.acronym,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      synced: item.synced,
    );
  }

  @override
  Future<void> insert(entity.MeasurementUnit measurementUnit) async {
    await database.into(database.measurementUnits).insert(
          MeasurementUnitsCompanion.insert(
            id: measurementUnit.id,
            userId: measurementUnit.userId,
            name: measurementUnit.name,
            acronym: measurementUnit.acronym,
          ),
        );

    // Log creation
    await auditService.logCreate(
      userId: measurementUnit.userId,
      entityType: 'measurement_unit',
      entityId: measurementUnit.id,
      newValues: {
        'name': measurementUnit.name,
        'acronym': measurementUnit.acronym,
      },
    );
  }

  @override
  Future<void> update(entity.MeasurementUnit measurementUnit) async {
    // Get old values for audit
    final oldUnit = await getById(measurementUnit.id);

    await (database.update(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(measurementUnit.id)))
        .write(
      MeasurementUnitsCompanion(
        userId: Value(measurementUnit.userId),
        name: Value(measurementUnit.name),
        acronym: Value(measurementUnit.acronym),
        updatedAt: Value(measurementUnit.updatedAt),
        synced: Value(measurementUnit.synced),
      ),
    );

    // Log update
    if (oldUnit != null) {
      await auditService.logUpdate(
        userId: measurementUnit.userId,
        entityType: 'measurement_unit',
        entityId: measurementUnit.id,
        oldValues: {
          'name': oldUnit.name,
          'acronym': oldUnit.acronym,
        },
        newValues: {
          'name': measurementUnit.name,
          'acronym': measurementUnit.acronym,
        },
      );
    }
  }

  @override
  Future<void> upsert(entity.MeasurementUnit measurementUnit) async {
    await database.into(database.measurementUnits).insertOnConflictUpdate(
      MeasurementUnitsCompanion.insert(
        id: measurementUnit.id,
        userId: measurementUnit.userId,
        name: measurementUnit.name,
        acronym: measurementUnit.acronym,
        createdAt: Value(measurementUnit.createdAt),
        updatedAt: Value(measurementUnit.updatedAt),
        synced: Value(measurementUnit.synced),
      ),
    );
  }

  @override
  Future<void> upsertAll(List<entity.MeasurementUnit> measurementUnits) async {
    await database.transaction(() async {
      for (final unit in measurementUnits) {
        await database.into(database.measurementUnits).insertOnConflictUpdate(
          MeasurementUnitsCompanion.insert(
            id: unit.id,
            userId: unit.userId,
            name: unit.name,
            acronym: unit.acronym,
            createdAt: Value(unit.createdAt),
            updatedAt: Value(unit.updatedAt),
            synced: Value(unit.synced),
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    // Get unit for audit before deletion
    final unit = await getById(id);

    await (database.delete(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    // Log deletion
    if (unit != null) {
      await auditService.logDelete(
        userId: unit.userId,
        entityType: 'measurement_unit',
        entityId: id,
        oldValues: {
          'name': unit.name,
          'acronym': unit.acronym,
        },
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    await database.delete(database.measurementUnits).go();
  }

  @override
  Future<List<entity.MeasurementUnit>> getUnsyncedItems() async {
    final items = await (database.select(database.measurementUnits)
          ..where((tbl) => tbl.synced.equals(false)))
        .get();

    return items
        .map((item) => entity.MeasurementUnit(
              id: item.id,
              userId: item.userId,
              name: item.name,
              acronym: item.acronym,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
            ))
        .toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const MeasurementUnitsCompanion(
      synced: Value(true),
    ));
  }
}
