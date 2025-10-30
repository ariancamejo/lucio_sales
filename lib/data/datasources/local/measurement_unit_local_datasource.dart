import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/measurement_unit.dart' as entity;
import '../../../domain/models/paginated_result.dart';

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

  MeasurementUnitLocalDataSourceImpl({required this.database});

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
  }

  @override
  Future<void> update(entity.MeasurementUnit measurementUnit) async {
    await (database.update(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(measurementUnit.id)))
        .write(
      MeasurementUnitsCompanion.insert(
        id: measurementUnit.id,
        userId: measurementUnit.userId,
        name: measurementUnit.name,
        acronym: measurementUnit.acronym,
      ),
    );
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
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.measurementUnits)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
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
