import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/product.dart' as entity;
import '../../../domain/models/paginated_result.dart';

abstract class ProductLocalDataSource {
  Future<List<entity.Product>> getAll({bool includeInactive = false});
  Future<PaginatedResult<entity.Product>> getPaginated({
    required int page,
    required int pageSize,
    bool includeInactive = false,
  });
  Future<int> getCount({bool includeInactive = false});
  Future<entity.Product?> getById(String id);
  Future<entity.Product?> getByCode(String code);
  Future<void> insert(entity.Product product);
  Future<void> update(entity.Product product);
  Future<void> upsert(entity.Product product);
  Future<void> upsertAll(List<entity.Product> products);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<List<entity.Product>> getUnsyncedItems();
  Future<void> markAsSynced(String id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final AppDatabase database;

  ProductLocalDataSourceImpl({required this.database});

  @override
  Future<List<entity.Product>> getAll({bool includeInactive = false}) async {
    var query = database.select(database.products);

    if (!includeInactive) {
      query = query..where((tbl) => tbl.active.equals(true));
    }

    final items = await query.get();
    return items
        .map((item) => entity.Product(
              id: item.id,
              userId: item.userId,
              name: item.name,
              quantity: item.quantity,
              code: item.code,
              cost: item.cost,
              measurementUnitId: item.measurementUnitId,
              price: item.price,
              active: item.active,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<PaginatedResult<entity.Product>> getPaginated({
    required int page,
    required int pageSize,
    bool includeInactive = false,
  }) async {
    var query = database.select(database.products);

    if (!includeInactive) {
      query = query..where((tbl) => tbl.active.equals(true));
    }

    final totalCount = await getCount(includeInactive: includeInactive);
    final offset = (page - 1) * pageSize;

    query = query
      ..limit(pageSize, offset: offset)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final items = await query.get();
    final products = items
        .map((item) => entity.Product(
              id: item.id,
              userId: item.userId,
              name: item.name,
              quantity: item.quantity,
              code: item.code,
              cost: item.cost,
              measurementUnitId: item.measurementUnitId,
              price: item.price,
              active: item.active,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();

    return PaginatedResult(
      items: products,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  @override
  Future<int> getCount({bool includeInactive = false}) async {
    var query = database.selectOnly(database.products)
      ..addColumns([database.products.id.count()]);

    if (!includeInactive) {
      query = query..where(database.products.active.equals(true));
    }

    final result = await query.getSingle();
    return result.read(database.products.id.count()) ?? 0;
  }

  @override
  Future<entity.Product?> getById(String id) async {
    final item = await (database.select(database.products)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;

    return entity.Product(
      id: item.id,
      userId: item.userId,
      name: item.name,
      quantity: item.quantity,
      code: item.code,
      cost: item.cost,
      measurementUnitId: item.measurementUnitId,
      price: item.price,
      active: item.active,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  @override
  Future<entity.Product?> getByCode(String code) async {
    final item = await (database.select(database.products)
          ..where((tbl) => tbl.code.equals(code)))
        .getSingleOrNull();

    if (item == null) return null;

    return entity.Product(
      id: item.id,
      userId: item.userId,
      name: item.name,
      quantity: item.quantity,
      code: item.code,
      cost: item.cost,
      measurementUnitId: item.measurementUnitId,
      price: item.price,
      active: item.active,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  @override
  Future<void> insert(entity.Product product) async {
    await database.into(database.products).insert(
          ProductsCompanion.insert(
            id: product.id,
            userId: product.userId,
            name: product.name,
            quantity: product.quantity,
            code: product.code,
            cost: product.cost,
            measurementUnitId: product.measurementUnitId,
            price: product.price,
            active: Value(product.active),
          ),
        );
  }

  @override
  Future<void> update(entity.Product product) async {
    await (database.update(database.products)
          ..where((tbl) => tbl.id.equals(product.id)))
        .write(
      ProductsCompanion.insert(
        id: product.id,
        userId: product.userId,
        name: product.name,
        quantity: product.quantity,
        code: product.code,
        cost: product.cost,
        measurementUnitId: product.measurementUnitId,
        price: product.price,
        active: Value(product.active),
      ),
    );
  }

  @override
  Future<void> upsert(entity.Product product) async {
    await database.into(database.products).insertOnConflictUpdate(
      ProductsCompanion.insert(
        id: product.id,
        userId: product.userId,
        name: product.name,
        quantity: product.quantity,
        code: product.code,
        cost: product.cost,
        measurementUnitId: product.measurementUnitId,
        price: product.price,
        active: Value(product.active),
        createdAt: Value(product.createdAt),
        updatedAt: Value(product.updatedAt),
      ),
    );
  }

  @override
  Future<void> upsertAll(List<entity.Product> products) async {
    await database.transaction(() async {
      for (final product in products) {
        await database.into(database.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: product.id,
            userId: product.userId,
            name: product.name,
            quantity: product.quantity,
            code: product.code,
            cost: product.cost,
            measurementUnitId: product.measurementUnitId,
            price: product.price,
            active: Value(product.active),
            createdAt: Value(product.createdAt),
            updatedAt: Value(product.updatedAt),
          ),
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.products)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await database.delete(database.products).go();
  }

  @override
  Future<List<entity.Product>> getUnsyncedItems() async {
    final items = await (database.select(database.products)
          ..where((tbl) => tbl.synced.equals(false)))
        .get();

    return items
        .map((item) => entity.Product(
              id: item.id,
              userId: item.userId,
              name: item.name,
              quantity: item.quantity,
              code: item.code,
              cost: item.cost,
              measurementUnitId: item.measurementUnitId,
              price: item.price,
              active: item.active,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.products)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const ProductsCompanion(
      synced: Value(true),
    ));
  }
}
