import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';
import 'base/base_offline_first_repository.dart';

class ProductRepositoryImpl extends BaseOfflineFirstRepository<Product, ProductRemoteDataSource, ProductLocalDataSource>
    implements ProductRepository {

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    ProductLocalDataSource? localDataSource,
    required NetworkInfo networkInfo,
  }) : super(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
          networkInfo: networkInfo,
        );

  // ========== Implementation of abstract methods from base class ==========

  @override
  String getEntityId(Product entity) => entity.id;

  @override
  bool isEntitySynced(Product entity) => entity.synced;

  @override
  bool hasDataChanges(Product local, Product remote) => local.hasDataChanges(remote);

  @override
  Future<List<Product>> getAllFromRemote() => remoteDataSource.getAll(includeInactive: false);

  @override
  Future<List<Product>> getAllFromLocal() => localDataSource!.getAll(includeInactive: false);

  @override
  Future<Product> getByIdFromRemote(String id) => remoteDataSource.getById(id);

  @override
  Future<Product?> getByIdFromLocal(String id) => localDataSource!.getById(id);

  @override
  Future<Product> createOnRemote(Product item) => remoteDataSource.create(item);

  @override
  Future<Product> updateOnRemote(Product item) => remoteDataSource.update(item);

  @override
  Future<void> deleteFromRemote(String id) => remoteDataSource.delete(id);

  @override
  Future<void> upsertAllToLocal(List<Product> items) => localDataSource!.upsertAll(items);

  @override
  Future<void> deleteFromLocal(String id) => localDataSource!.delete(id);

  @override
  Future<List<Product>> getUnsyncedFromLocal() => localDataSource!.getUnsyncedItems();

  @override
  Future<void> markAsSyncedInLocal(String id) => localDataSource!.markAsSynced(id);

  // ========== Repository methods using base class ==========

  @override
  Future<Either<Failure, List<Product>>> getAll({bool includeInactive = false}) {
    // Use base implementation
    return baseGetAll();
  }

  @override
  Future<Either<Failure, Product>> getById(String id) {
    // Use base implementation
    return baseGetById(id);
  }

  @override
  Future<Either<Failure, void>> delete(String id) {
    // Use base implementation
    return baseDelete(id);
  }

  @override
  Future<Either<Failure, void>> sync() {
    // Use base implementation
    return baseSync();
  }

  // ========== Custom methods specific to Product ==========

  @override
  Future<Either<Failure, PaginatedResult<Product>>> getPaginated({
    required int page,
    required int pageSize,
    bool includeInactive = false,
  }) async {
    try {
      // WEB: Fetch from remote and create pagination manually
      if (PlatformInfo.isWeb) {
        final allItems = await remoteDataSource.getAll(includeInactive: includeInactive);
        final totalCount = allItems.length;
        final offset = (page - 1) * pageSize;
        final items = allItems.skip(offset).take(pageSize).toList();

        return Right(PaginatedResult(
          items: items,
          page: page,
          pageSize: pageSize,
          totalCount: totalCount,
        ));
      }

      // NATIVE: Sync from server on first page when connected
      final isConnected = await networkInfo.isConnected;
      if (isConnected && page == 1) {
        try {
          print('🔄 [ProductRepo] Syncing from server...');

          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll(includeInactive: includeInactive);
          print('📥 [ProductRepo] Got ${remoteItems.length} items from remote');

          // Debug: Check synced status of remote items
          final remoteSyncedCount = remoteItems.where((item) => item.synced).length;
          print('✅ [ProductRepo] Remote items marked as synced: $remoteSyncedCount/${remoteItems.length}');

          final localItems = await localDataSource!.getAll(includeInactive: includeInactive);
          print('💾 [ProductRepo] Got ${localItems.length} items from local');

          // Debug: Check synced status of local items BEFORE upsert
          final localSyncedCount = localItems.where((item) => item.synced).length;
          print('✅ [ProductRepo] Local items marked as synced (before): $localSyncedCount/${localItems.length}');

          // Build a map of local items by ID for quick lookup
          final localItemsMap = {for (var item in localItems) item.id: item};

          // Determine which items have REAL local changes (not just synced=false)
          // An item has real changes if:
          // 1. It has synced=false AND
          // 2. Its data is different from the server (using hasDataChanges method)
          final itemsWithRealChanges = <String>{};
          for (var remoteItem in remoteItems) {
            final localItem = localItemsMap[remoteItem.id];
            if (localItem != null && !localItem.synced) {
              // Use the hasDataChanges method from Product entity
              if (localItem.hasDataChanges(remoteItem)) {
                itemsWithRealChanges.add(localItem.id);
                print('🔄 [ProductRepo] Item ${localItem.name} has real local changes, preserving');
              }
            }
          }

          print('⏳ [ProductRepo] Items with REAL local changes: ${itemsWithRealChanges.length}');

          // Only upsert remote items that don't have real local changes
          final itemsToUpsert = remoteItems
              .where((item) => !itemsWithRealChanges.contains(item.id))
              .toList();

          print('📝 [ProductRepo] Upserting ${itemsToUpsert.length} items to local');
          await localDataSource!.upsertAll(itemsToUpsert);

          // Verify: Check synced status AFTER upsert
          final localItemsAfter = await localDataSource!.getAll(includeInactive: includeInactive);
          final localSyncedCountAfter = localItemsAfter.where((item) => item.synced).length;
          print('✅ [ProductRepo] Local items marked as synced (after): $localSyncedCountAfter/${localItemsAfter.length}');

          // Find local items that are NOT in remote and were previously synced
          // Delete them as they were deleted from another device
          final remoteIds = remoteItems.map((item) => item.id).toSet();
          int deletedCount = 0;
          for (var localItem in localItems) {
            if (!remoteIds.contains(localItem.id) && localItem.synced) {
              await localDataSource!.delete(localItem.id);
              deletedCount++;
            }
          }

          if (deletedCount > 0) {
            print('🗑️ [ProductRepo] Deleted $deletedCount items that were removed from server');
          }

          print('✅ [ProductRepo] Sync completed successfully');
        } catch (e) {
          print('❌ [ProductRepo] Sync failed: $e');
          // If sync fails, continue with local data
        }
      }

      // Always fetch from local database for fast response
      final result = await localDataSource!.getPaginated(
        page: page,
        pageSize: pageSize,
        includeInactive: includeInactive,
      );

      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product?>> getByCode(String code) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.getByCode(code);
        return Right(remoteItem);
      }

      // NATIVE: Try local first, then remote
      final localItem = await localDataSource!.getByCode(code);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getByCode(code);
        if (remoteItem != null) {
          await localDataSource!.insert(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
        }
        return Right(remoteItem);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> create(Product product) async {
    try {
      final newItem = product.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WEB: Only create on remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.create(newItem);
        return Right(remoteItem);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.create(newItem);
          await localDataSource!.insert(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote create fails, mark as not synced
          final unsyncedItem = newItem.copyWith(synced: false);
          await localDataSource!.insert(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = newItem.copyWith(synced: false);
        await localDataSource!.insert(unsyncedItem);
        return Right(unsyncedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> update(Product product) async {
    try {
      final updatedItem = product.copyWith(
        updatedAt: DateTime.now(),
      );

      // WEB: Only update on remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.update(updatedItem);
        return Right(remoteItem);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.update(updatedItem);
          await localDataSource!.update(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote update fails, mark as not synced
          final unsyncedItem = updatedItem.copyWith(synced: false);
          await localDataSource!.update(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = updatedItem.copyWith(synced: false);
        await localDataSource!.update(unsyncedItem);
        return Right(unsyncedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
