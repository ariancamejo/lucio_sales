import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/output.dart' as entity;
import '../../../domain/entities/product.dart' as entity;
import '../../../domain/entities/measurement_unit.dart' as entity;
import '../../../domain/entities/output_type.dart' as entity;
import '../../../domain/models/paginated_result.dart';

abstract class OutputLocalDataSource {
  Future<List<entity.Output>> getAll();
  Future<PaginatedResult<entity.Output>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<int> getCount();
  Future<entity.Output?> getById(String id);
  Future<List<entity.Output>> getByDateRange(DateTime start, DateTime end);
  Future<List<entity.Output>> getByType(String outputTypeId);
  Future<void> insert(entity.Output output);
  Future<void> update(entity.Output output);
  Future<void> upsert(entity.Output output);
  Future<void> upsertAll(List<entity.Output> outputs);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<List<entity.Output>> getUnsyncedItems();
  Future<void> markAsSynced(String id);
}

class OutputLocalDataSourceImpl implements OutputLocalDataSource {
  final AppDatabase database;

  OutputLocalDataSourceImpl({required this.database});

  @override
  Future<List<entity.Output>> getAll() async {
    final query = database.select(database.outputs).join([
      leftOuterJoin(database.products,
          database.products.id.equalsExp(database.outputs.productId)),
      leftOuterJoin(
          database.measurementUnits,
          database.measurementUnits.id
              .equalsExp(database.outputs.measurementUnitId)),
      leftOuterJoin(database.outputTypes,
          database.outputTypes.id.equalsExp(database.outputs.outputTypeId)),
    ])
      ..orderBy([OrderingTerm.desc(database.outputs.date)]);

    final results = await query.get();

    return results.map((row) {
      final output = row.readTable(database.outputs);
      final product = row.readTableOrNull(database.products);
      final measurementUnit = row.readTableOrNull(database.measurementUnits);
      final outputType = row.readTableOrNull(database.outputTypes);

      return entity.Output(
        id: output.id,
        userId: output.userId,
        productId: output.productId,
        quantity: output.quantity,
        measurementUnitId: output.measurementUnitId,
        totalAmount: output.totalAmount,
        outputTypeId: output.outputTypeId,
        date: output.date,
        createdAt: output.createdAt,
        updatedAt: output.updatedAt,
        product: product != null
            ? entity.Product(
                id: product.id,
                userId: product.userId,
                name: product.name,
                code: product.code,
                price: product.price,
                cost: product.cost,
                quantity: product.quantity,
                measurementUnitId: product.measurementUnitId,
                active: product.active,
                createdAt: product.createdAt,
                updatedAt: product.updatedAt,
              )
            : null,
        measurementUnit: measurementUnit != null
            ? entity.MeasurementUnit(
                id: measurementUnit.id,
                userId: measurementUnit.userId,
                name: measurementUnit.name,
                acronym: measurementUnit.acronym,
                createdAt: measurementUnit.createdAt,
                updatedAt: measurementUnit.updatedAt,
              )
            : null,
        outputType: outputType != null
            ? entity.OutputType(
                id: outputType.id,
                userId: outputType.userId,
                name: outputType.name,
                createdAt: outputType.createdAt,
                updatedAt: outputType.updatedAt,
              )
            : null,
      );
    }).toList();
  }

  @override
  Future<PaginatedResult<entity.Output>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    final totalCount = await getCount();
    final offset = (page - 1) * pageSize;

    final query = database.select(database.outputs).join([
      leftOuterJoin(database.products,
          database.products.id.equalsExp(database.outputs.productId)),
      leftOuterJoin(
          database.measurementUnits,
          database.measurementUnits.id
              .equalsExp(database.outputs.measurementUnitId)),
      leftOuterJoin(database.outputTypes,
          database.outputTypes.id.equalsExp(database.outputs.outputTypeId)),
    ])
      ..orderBy([OrderingTerm.desc(database.outputs.date)])
      ..limit(pageSize, offset: offset);

    final results = await query.get();

    final outputs = results.map((row) {
      final output = row.readTable(database.outputs);
      final product = row.readTableOrNull(database.products);
      final measurementUnit = row.readTableOrNull(database.measurementUnits);
      final outputType = row.readTableOrNull(database.outputTypes);

      return entity.Output(
        id: output.id,
        userId: output.userId,
        productId: output.productId,
        quantity: output.quantity,
        measurementUnitId: output.measurementUnitId,
        totalAmount: output.totalAmount,
        outputTypeId: output.outputTypeId,
        date: output.date,
        createdAt: output.createdAt,
        updatedAt: output.updatedAt,
        product: product != null
            ? entity.Product(
                id: product.id,
                userId: product.userId,
                name: product.name,
                code: product.code,
                price: product.price,
                cost: product.cost,
                quantity: product.quantity,
                measurementUnitId: product.measurementUnitId,
                active: product.active,
                createdAt: product.createdAt,
                updatedAt: product.updatedAt,
              )
            : null,
        measurementUnit: measurementUnit != null
            ? entity.MeasurementUnit(
                id: measurementUnit.id,
                userId: measurementUnit.userId,
                name: measurementUnit.name,
                acronym: measurementUnit.acronym,
                createdAt: measurementUnit.createdAt,
                updatedAt: measurementUnit.updatedAt,
              )
            : null,
        outputType: outputType != null
            ? entity.OutputType(
                id: outputType.id,
                userId: outputType.userId,
                name: outputType.name,
                createdAt: outputType.createdAt,
                updatedAt: outputType.updatedAt,
              )
            : null,
      );
    }).toList();

    return PaginatedResult(
      items: outputs,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  @override
  Future<int> getCount() async {
    var query = database.selectOnly(database.outputs)
      ..addColumns([database.outputs.id.count()]);

    final result = await query.getSingle();
    return result.read(database.outputs.id.count()) ?? 0;
  }

  @override
  Future<entity.Output?> getById(String id) async {
    final item = await (database.select(database.outputs)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;

    return entity.Output(
      id: item.id,
      userId: item.userId,
      productId: item.productId,
      quantity: item.quantity,
      measurementUnitId: item.measurementUnitId,
      totalAmount: item.totalAmount,
      outputTypeId: item.outputTypeId,
      date: item.date,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  @override
  Future<List<entity.Output>> getByDateRange(DateTime start, DateTime end) async {
    final items = await (database.select(database.outputs)
          ..where((tbl) =>
              tbl.date.isBiggerOrEqualValue(start) &
              tbl.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return items
        .map((item) => entity.Output(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: item.quantity,
              measurementUnitId: item.measurementUnitId,
              totalAmount: item.totalAmount,
              outputTypeId: item.outputTypeId,
              date: item.date,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<List<entity.Output>> getByType(String outputTypeId) async {
    final items = await (database.select(database.outputs)
          ..where((tbl) => tbl.outputTypeId.equals(outputTypeId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    return items
        .map((item) => entity.Output(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: item.quantity,
              measurementUnitId: item.measurementUnitId,
              totalAmount: item.totalAmount,
              outputTypeId: item.outputTypeId,
              date: item.date,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<void> insert(entity.Output output) async {
    await database.into(database.outputs).insert(
          OutputsCompanion.insert(
            id: output.id,
            userId: output.userId,
            productId: output.productId,
            quantity: output.quantity,
            measurementUnitId: output.measurementUnitId,
            totalAmount: output.totalAmount,
            outputTypeId: output.outputTypeId,
            date: output.date,
          ),
        );
  }

  @override
  Future<void> update(entity.Output output) async {
    await (database.update(database.outputs)
          ..where((tbl) => tbl.id.equals(output.id)))
        .write(
      OutputsCompanion.insert(
        id: output.id,
        userId: output.userId,
        productId: output.productId,
        quantity: output.quantity,
        measurementUnitId: output.measurementUnitId,
        totalAmount: output.totalAmount,
        outputTypeId: output.outputTypeId,
        date: output.date,
      ),
    );
  }

  @override
  Future<void> upsert(entity.Output output) async {
    await database.into(database.outputs).insertOnConflictUpdate(
      OutputsCompanion.insert(
        id: output.id,
        userId: output.userId,
        productId: output.productId,
        quantity: output.quantity,
        measurementUnitId: output.measurementUnitId,
        totalAmount: output.totalAmount,
        outputTypeId: output.outputTypeId,
        date: output.date,
        createdAt: Value(output.createdAt),
        updatedAt: Value(output.updatedAt),
      ),
    );
  }

  @override
  Future<void> upsertAll(List<entity.Output> outputs) async {
    await database.transaction(() async {
      for (final output in outputs) {
        await database.into(database.outputs).insertOnConflictUpdate(
          OutputsCompanion.insert(
            id: output.id,
            userId: output.userId,
            productId: output.productId,
            quantity: output.quantity,
            measurementUnitId: output.measurementUnitId,
            totalAmount: output.totalAmount,
            outputTypeId: output.outputTypeId,
            date: output.date,
            createdAt: Value(output.createdAt),
            updatedAt: Value(output.updatedAt),
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.outputs)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await database.delete(database.outputs).go();
  }

  @override
  Future<List<entity.Output>> getUnsyncedItems() async {
    final items = await (database.select(database.outputs)
          ..where((tbl) => tbl.synced.equals(false)))
        .get();

    return items
        .map((item) => entity.Output(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: item.quantity,
              measurementUnitId: item.measurementUnitId,
              totalAmount: item.totalAmount,
              outputTypeId: item.outputTypeId,
              date: item.date,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.outputs)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const OutputsCompanion(
      synced: Value(true),
    ));
  }
}
