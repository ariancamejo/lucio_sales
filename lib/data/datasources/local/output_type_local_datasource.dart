import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/output_type.dart' as entity;
import '../../../domain/models/paginated_result.dart';
import '../../../core/services/audit_service.dart';

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
  late final AuditService auditService;

  OutputTypeLocalDataSourceImpl({required this.database}) {
    auditService = AuditService(database: database);
  }

  @override
  Future<List<entity.OutputType>> getAll() async {
    final items = await database.select(database.outputTypes).get();
    return items
        .map((item) => entity.OutputType(
              id: item.id,
              userId: item.userId,
              name: item.name,
              isDefault: item.isDefault,
              isSale: item.isSale,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
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
              isDefault: item.isDefault,
              isSale: item.isSale,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
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
      isDefault: item.isDefault,
      isSale: item.isSale,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      synced: item.synced,
    );
  }

  @override
  Future<void> insert(entity.OutputType outputType) async {
    await database.into(database.outputTypes).insert(
          OutputTypesCompanion.insert(
            id: outputType.id,
            userId: outputType.userId,
            name: outputType.name,
            isDefault: Value(outputType.isDefault),
            isSale: Value(outputType.isSale),
          ),
        );

    // Log creation
    await auditService.logCreate(
      userId: outputType.userId,
      entityType: 'output_type',
      entityId: outputType.id,
      newValues: {
        'name': outputType.name,
        'isDefault': outputType.isDefault,
        'isSale': outputType.isSale,
      },
    );
  }

  @override
  Future<void> update(entity.OutputType outputType) async{
    // Get old values for audit
    final oldType = await getById(outputType.id);

    await (database.update(database.outputTypes)
          ..where((tbl) => tbl.id.equals(outputType.id)))
        .write(
      OutputTypesCompanion(
        userId: Value(outputType.userId),
        name: Value(outputType.name),
        isDefault: Value(outputType.isDefault),
        isSale: Value(outputType.isSale),
        updatedAt: Value(outputType.updatedAt),
        synced: Value(outputType.synced),
      ),
    );

    // Log update
    if (oldType != null) {
      await auditService.logUpdate(
        userId: outputType.userId,
        entityType: 'output_type',
        entityId: outputType.id,
        oldValues: {
          'name': oldType.name,
          'isDefault': oldType.isDefault,
          'isSale': oldType.isSale,
        },
        newValues: {
          'name': outputType.name,
          'isDefault': outputType.isDefault,
          'isSale': outputType.isSale,
        },
      );
    }
  }

  @override
  Future<void> upsert(entity.OutputType outputType) async {
    await database.into(database.outputTypes).insertOnConflictUpdate(
      OutputTypesCompanion.insert(
        id: outputType.id,
        userId: outputType.userId,
        name: outputType.name,
        isDefault: Value(outputType.isDefault),
        isSale: Value(outputType.isSale),
        createdAt: Value(outputType.createdAt),
        updatedAt: Value(outputType.updatedAt),
        synced: Value(outputType.synced),
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
            isDefault: Value(type.isDefault),
            isSale: Value(type.isSale),
            createdAt: Value(type.createdAt),
            updatedAt: Value(type.updatedAt),
            synced: Value(type.synced),
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    // Get type for audit before deletion
    final type = await getById(id);

    await (database.delete(database.outputTypes)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    // Log deletion
    if (type != null) {
      await auditService.logDelete(
        userId: type.userId,
        entityType: 'output_type',
        entityId: id,
        oldValues: {
          'name': type.name,
        },
      );
    }
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
              isDefault: item.isDefault,
              isSale: item.isSale,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
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
