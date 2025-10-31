import '../../../core/database/app_database.dart';
import '../../../domain/entities/product_entry.dart' as entity;
import '../../../domain/entities/product.dart' as entity;
import '../../../domain/models/paginated_result.dart';
import 'package:drift/drift.dart';
import '../../../core/services/audit_service.dart';

abstract class ProductEntryLocalDataSource {
  Future<List<entity.ProductEntry>> getAll({String? userId});
  Future<PaginatedResult<entity.ProductEntry>> getPaginated({
    required int page,
    required int pageSize,
    String? userId,
  });
  Future<int> getCount({String? userId});
  Future<List<entity.ProductEntry>> getByProductId(String productId);
  Future<entity.ProductEntry> getById(String id);
  Future<void> insert(entity.ProductEntry productEntry);
  Future<void> update(entity.ProductEntry productEntry);
  Future<void> delete(String id);
  Future<void> upsertAll(List<entity.ProductEntry> productEntries);
  Future<void> markAsSynced(String id);
  Future<List<entity.ProductEntry>> getUnsynced();
}

class ProductEntryLocalDataSourceImpl implements ProductEntryLocalDataSource {
  final AppDatabase database;
  late final AuditService auditService;

  ProductEntryLocalDataSourceImpl(this.database) {
    auditService = AuditService(database: database);
  }

  @override
  Future<List<entity.ProductEntry>> getAll({String? userId}) async {
    final query = database.select(database.productEntries).join([
      leftOuterJoin(
        database.products,
        database.products.id.equalsExp(database.productEntries.productId),
      ),
    ]);

    if (userId != null) {
      query.where(database.productEntries.userId.equals(userId));
    }

    query.orderBy([OrderingTerm.desc(database.productEntries.date)]);

    final results = await query.get();

    return results.map((row) {
      final entry = row.readTable(database.productEntries);
      final product = row.readTableOrNull(database.products);

      return entity.ProductEntry(
        id: entry.id,
        userId: entry.userId,
        productId: entry.productId,
        quantity: entry.quantity,
        date: entry.date,
        notes: entry.notes,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        synced: entry.synced,
        product: product != null
            ? _productFromRow(product)
            : null,
      );
    }).toList();
  }

  entity.Product _productFromRow(Product product) {
    return entity.Product(
      id: product.id,
      userId: product.userId,
      name: product.name,
      quantity: product.quantity,
      code: product.code,
      cost: product.cost,
      measurementUnitId: product.measurementUnitId,
      price: product.price,
      active: product.active,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      synced: product.synced,
    );
  }

  @override
  Future<PaginatedResult<entity.ProductEntry>> getPaginated({
    required int page,
    required int pageSize,
    String? userId,
  }) async {
    final query = database.select(database.productEntries).join([
      leftOuterJoin(
        database.products,
        database.products.id.equalsExp(database.productEntries.productId),
      ),
    ]);

    if (userId != null) {
      query.where(database.productEntries.userId.equals(userId));
    }

    final totalCount = await getCount(userId: userId);
    final offset = (page - 1) * pageSize;

    query
      ..limit(pageSize, offset: offset)
      ..orderBy([OrderingTerm.desc(database.productEntries.date)]);

    final results = await query.get();
    final productEntries = results.map((row) {
      final entry = row.readTable(database.productEntries);
      final product = row.readTableOrNull(database.products);

      return entity.ProductEntry(
        id: entry.id,
        userId: entry.userId,
        productId: entry.productId,
        quantity: entry.quantity,
        date: entry.date,
        notes: entry.notes,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        synced: entry.synced,
        product: product != null
            ? _productFromRow(product)
            : null,
      );
    }).toList();

    return PaginatedResult(
      items: productEntries,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  @override
  Future<int> getCount({String? userId}) async {
    var query = database.selectOnly(database.productEntries)
      ..addColumns([database.productEntries.id.count()]);

    if (userId != null) {
      query = query..where(database.productEntries.userId.equals(userId));
    }

    final result = await query.getSingle();
    return result.read(database.productEntries.id.count()) ?? 0;
  }

  @override
  Future<List<entity.ProductEntry>> getByProductId(String productId) async {
    final query = database.select(database.productEntries).join([
      leftOuterJoin(
        database.products,
        database.products.id.equalsExp(database.productEntries.productId),
      ),
    ])
      ..where(database.productEntries.productId.equals(productId))
      ..orderBy([OrderingTerm.desc(database.productEntries.date)]);

    final results = await query.get();

    return results.map((row) {
      final entry = row.readTable(database.productEntries);
      final product = row.readTableOrNull(database.products);

      return entity.ProductEntry(
        id: entry.id,
        userId: entry.userId,
        productId: entry.productId,
        quantity: entry.quantity,
        date: entry.date,
        notes: entry.notes,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        synced: entry.synced,
        product: product != null
            ? _productFromRow(product)
            : null,
      );
    }).toList();
  }

  @override
  Future<entity.ProductEntry> getById(String id) async {
    final query = database.select(database.productEntries).join([
      leftOuterJoin(
        database.products,
        database.products.id.equalsExp(database.productEntries.productId),
      ),
    ])..where(database.productEntries.id.equals(id));

    final result = await query.getSingle();
    final entry = result.readTable(database.productEntries);
    final product = result.readTableOrNull(database.products);

    return entity.ProductEntry(
      id: entry.id,
      userId: entry.userId,
      productId: entry.productId,
      quantity: entry.quantity,
      date: entry.date,
      notes: entry.notes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      synced: entry.synced,
      product: product != null
          ? _productFromRow(product)
          : null,
    );
  }

  @override
  Future<void> insert(entity.ProductEntry productEntry) async {
    await database.into(database.productEntries).insert(
          ProductEntriesCompanion.insert(
            id: productEntry.id,
            userId: productEntry.userId,
            productId: productEntry.productId,
            quantity: productEntry.quantity,
            date: productEntry.date,
            notes: Value(productEntry.notes),
            createdAt: Value(productEntry.createdAt),
            updatedAt: Value(productEntry.updatedAt),
          ),
        );

    // Log creation
    await auditService.logCreate(
      userId: productEntry.userId,
      entityType: 'product_entry',
      entityId: productEntry.id,
      newValues: {
        'productId': productEntry.productId,
        'quantity': productEntry.quantity,
        'date': productEntry.date.toIso8601String(),
        'notes': productEntry.notes,
      },
    );
  }

  @override
  Future<void> update(entity.ProductEntry productEntry) async {
    // Get old values for audit
    final oldEntry = await getById(productEntry.id);

    await (database.update(database.productEntries)
          ..where((tbl) => tbl.id.equals(productEntry.id)))
        .write(
      ProductEntriesCompanion(
        userId: Value(productEntry.userId),
        productId: Value(productEntry.productId),
        quantity: Value(productEntry.quantity),
        date: Value(productEntry.date),
        notes: Value(productEntry.notes),
        updatedAt: Value(productEntry.updatedAt),
        synced: Value(productEntry.synced),
      ),
    );

    // Log update
    await auditService.logUpdate(
      userId: productEntry.userId,
      entityType: 'product_entry',
      entityId: productEntry.id,
      oldValues: {
        'productId': oldEntry.productId,
        'quantity': oldEntry.quantity,
        'date': oldEntry.date.toIso8601String(),
        'notes': oldEntry.notes,
      },
      newValues: {
        'productId': productEntry.productId,
        'quantity': productEntry.quantity,
        'date': productEntry.date.toIso8601String(),
        'notes': productEntry.notes,
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    // Get entry for audit before deletion
    final entry = await getById(id);

    await (database.delete(database.productEntries)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    // Log deletion
    await auditService.logDelete(
      userId: entry.userId,
      entityType: 'product_entry',
      entityId: id,
      oldValues: {
        'productId': entry.productId,
        'quantity': entry.quantity,
        'date': entry.date.toIso8601String(),
        'notes': entry.notes,
      },
    );
  }

  @override
  Future<void> upsertAll(List<entity.ProductEntry> productEntries) async {
    for (final productEntry in productEntries) {
      await database
          .into(database.productEntries)
          .insertOnConflictUpdate(ProductEntriesCompanion.insert(
            id: productEntry.id,
            userId: productEntry.userId,
            productId: productEntry.productId,
            quantity: productEntry.quantity,
            date: productEntry.date,
            notes: Value(productEntry.notes),
            createdAt: Value(productEntry.createdAt),
            updatedAt: Value(productEntry.updatedAt),
            synced: Value(productEntry.synced),
          ));
    }
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.productEntries)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const ProductEntriesCompanion(
      synced: Value(true),
    ));
  }

  @override
  Future<List<entity.ProductEntry>> getUnsynced() async {
    final items = await (database.select(database.productEntries)
          ..where((tbl) => tbl.synced.equals(false)))
        .get();

    return items
        .map((item) => entity.ProductEntry(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: item.quantity,
              date: item.date,
              notes: item.notes,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              synced: item.synced,
            ))
        .toList();
  }
}
