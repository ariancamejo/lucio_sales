import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/output_type.dart' as entity;
import '../../../domain/models/paginated_result.dart';

abstract class OutputTypeLocalDataSource {
  Future<List<entity.OutputType>> getAll();
  Future<PaginatedResult<entity.OutputType>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<int> getCount();
  Future<entity.OutputType?> getById(String id);
  Future<void> insert(entity.OutputType outputType);
  Future<void> update(entity.OutputType outputType);
  Future<void> upsert(entity.OutputType outputType);
  Future<void> upsertAll(List<entity.OutputType> outputTypes);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<List<entity.OutputType>> getUnsyncedItems();
  Future<void> markAsSynced(String id);
}

class OutputTypeLocalDataSourceImpl implements OutputTypeLocalDataSource {
  final AppDatabase database;

  OutputTypeLocalDataSourceImpl({required this.database});

  @override
  Future<List<entity.OutputType>> getAll() async {
    final items = await database.select(database.outputTypes).get();
    return items
        .map((item) => entity.OutputType(
              id: item.id,
              userId: item.userId,
              name: item.name,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<PaginatedResult<entity.OutputType>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    var query = database.select(database.outputTypes);

    final totalCount = await getCount();
    final offset = (page - 1) * pageSize;

    query = query
      ..limit(pageSize, offset: offset)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final items = await query.get();
    final outputTypes = items
        .map((item) => entity.OutputType(
              id: item.id,
              userId: item.userId,
              name: item.name,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();

    return PaginatedResult(
      items: outputTypes,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  @override
  Future<int> getCount() async {
    var query = database.selectOnly(database.outputTypes)
      ..addColumns([database.outputTypes.id.count()]);

    final result = await query.getSingle();
    return result.read(database.outputTypes.id.count()) ?? 0;
  }

  @override
  Future<entity.OutputType?> getById(String id) async {
    final item = await (database.select(database.outputTypes)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;

    return entity.OutputType(
      id: item.id,
      userId: item.userId,
      name: item.name,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  @override
  Future<void> insert(entity.OutputType outputType) async {
    await database.into(database.outputTypes).insert(
          OutputTypesCompanion.insert(
            id: outputType.id,
            userId: outputType.userId,
            name: outputType.name,
          ),
        );
  }

  @override
  Future<void> update(entity.OutputType outputType) async{
    await (database.update(database.outputTypes)
          ..where((tbl) => tbl.id.equals(outputType.id)))
        .write(
      OutputTypesCompanion.insert(
        id: outputType.id,
        userId: outputType.userId,
        name: outputType.name,
      ),
    );
  }

  @override
  Future<void> upsert(entity.OutputType outputType) async {
    await database.into(database.outputTypes).insertOnConflictUpdate(
      OutputTypesCompanion.insert(
        id: outputType.id,
        userId: outputType.userId,
        name: outputType.name,
        createdAt: Value(outputType.createdAt),
        updatedAt: Value(outputType.updatedAt),
      ),
    );
  }

  @override
  Future<void> upsertAll(List<entity.OutputType> outputTypes) async {
    await database.transaction(() async {
      for (final type in outputTypes) {
        await database.into(database.outputTypes).insertOnConflictUpdate(
          OutputTypesCompanion.insert(
            id: type.id,
            userId: type.userId,
            name: type.name,
            createdAt: Value(type.createdAt),
            updatedAt: Value(type.updatedAt),
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.outputTypes)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await database.delete(database.outputTypes).go();
  }

  @override
  Future<List<entity.OutputType>> getUnsyncedItems() async {
    final items = await (database.select(database.outputTypes)
          ..where((tbl) => tbl.synced.equals(false)))
        .get();

    return items
        .map((item) => entity.OutputType(
              id: item.id,
              userId: item.userId,
              name: item.name,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.outputTypes)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const OutputTypesCompanion(
      synced: Value(true),
    ));
  }
}
