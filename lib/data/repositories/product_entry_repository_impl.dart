import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/product_entry.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/product_entry_repository.dart';
import '../datasources/local/product_entry_local_datasource.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_entry_remote_datasource.dart';
import 'base/base_offline_first_repository.dart';

class ProductEntryRepositoryImpl extends BaseOfflineFirstRepository<ProductEntry, ProductEntryRemoteDataSource, ProductEntryLocalDataSource>
    implements ProductEntryRepository {
  final ProductLocalDataSource? productLocalDataSource;
  final AuthService authService;

  ProductEntryRepositoryImpl({
    required ProductEntryRemoteDataSource remoteDataSource,
    ProductEntryLocalDataSource? localDataSource,
    this.productLocalDataSource,
    required NetworkInfo networkInfo,
    required this.authService,
  }) : super(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
          networkInfo: networkInfo,
        );

  // ========== Implementation of abstract methods from base class ==========

  @override
  String getEntityId(ProductEntry entity) => entity.id;

  @override
  bool isEntitySynced(ProductEntry entity) => entity.synced;

  @override
  bool hasDataChanges(ProductEntry local, ProductEntry remote) => local.hasDataChanges(remote);

  @override
  Future<List<ProductEntry>> getAllFromRemote() => remoteDataSource.getAll();

  @override
  Future<List<ProductEntry>> getAllFromLocal() => localDataSource!.getAll(userId: authService.currentUser?.id);

  @override
  Future<ProductEntry> getByIdFromRemote(String id) => remoteDataSource.getById(id);

  @override
  Future<ProductEntry?> getByIdFromLocal(String id) => localDataSource!.getById(id);

  @override
  Future<ProductEntry> createOnRemote(ProductEntry item) => remoteDataSource.create(item);

  @override
  Future<ProductEntry> updateOnRemote(ProductEntry item) => remoteDataSource.update(item);

  @override
  Future<void> deleteFromRemote(String id) => remoteDataSource.delete(id);

  @override
  Future<void> upsertAllToLocal(List<ProductEntry> items) => localDataSource!.upsertAll(items);

  @override
  Future<void> deleteFromLocal(String id) => localDataSource!.delete(id);

  @override
  Future<List<ProductEntry>> getUnsyncedFromLocal() => localDataSource!.getUnsynced();

  @override
  Future<void> markAsSyncedInLocal(String id) => localDataSource!.markAsSynced(id);

  // ========== Repository methods ==========

  @override
  Future<Either<Failure, List<ProductEntry>>> getAll() async {
    try {
      // WEB: Only use remote datasource (online-only)
      if (PlatformInfo.isWeb) {
        final remoteItems = await remoteDataSource.getAll();
        return Right(remoteItems);
      }

      // NATIVE: Use offline-first strategy with local database
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll();
          final localItems = await localDataSource!.getAll(userId: userId);

          // Get items that have pending changes (not synced)
          final unsyncedIds = localItems
              .where((item) => !item.synced)
              .map((item) => item.id)
              .toSet();

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource!.upsertAll(productsToSync);
          }

          // Only upsert remote items that don't have pending local changes
          final itemsToUpsert = remoteItems
              .where((item) => !unsyncedIds.contains(item.id))
              .toList();

          await localDataSource!.upsertAll(itemsToUpsert);

          // Find local items that are NOT in remote and were previously synced
          // Delete them as they were deleted from another device
          // Keep items with synced=false (they're pending sync)
          final remoteIds = remoteItems.map((item) => item.id).toSet();
          for (var localItem in localItems) {
            if (!remoteIds.contains(localItem.id) && localItem.synced) {
              await localDataSource!.delete(localItem.id);
            }
          }

          // Reload from local to get Product relations + unsynced items
          final updatedLocalItems = await localDataSource!.getAll(userId: userId);
          return Right(updatedLocalItems);
        } catch (e) {
          final localItems = await localDataSource!.getAll(userId: userId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource!.getAll(userId: userId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<ProductEntry>>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      // WEB: Fetch from remote and create pagination manually
      if (PlatformInfo.isWeb) {
        final allItems = await remoteDataSource.getAll();
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

      // NATIVE: Use offline-first strategy with local database
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      // Sync from server on first page when connected
      if (isConnected && page == 1) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll();
          final localItems = await localDataSource!.getAll(userId: userId);

          // Get items that have pending changes (not synced)
          final unsyncedIds = localItems
              .where((item) => !item.synced)
              .map((item) => item.id)
              .toSet();

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource!.upsertAll(productsToSync);
          }

          // Only upsert remote items that don't have pending local changes
          final itemsToUpsert = remoteItems
              .where((item) => !unsyncedIds.contains(item.id))
              .toList();

          await localDataSource!.upsertAll(itemsToUpsert);

          // Find local items that are NOT in remote and were previously synced
          // Delete them as they were deleted from another device
          // Keep items with synced=false (they're pending sync)
          final remoteIds = remoteItems.map((item) => item.id).toSet();
          for (var localItem in localItems) {
            if (!remoteIds.contains(localItem.id) && localItem.synced) {
              await localDataSource!.delete(localItem.id);
            }
          }
        } catch (e) {
          // Continue with local data if sync fails
        }
      }

      final result = await localDataSource!.getPaginated(
        page: page,
        pageSize: pageSize,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntry>>> getByProductId(String productId) async {
    try {
      // WEB: Only use remote datasource
      if (PlatformInfo.isWeb) {
        final remoteItems = await remoteDataSource.getByProductId(productId);
        return Right(remoteItems);
      }

      // NATIVE: Use offline-first strategy
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByProductId(productId);

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource!.upsertAll(productsToSync);
          }

          await localDataSource!.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource!.markAsSynced(item.id);
          }
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource!.getByProductId(productId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource!.getByProductId(productId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> getById(String id) async {
    try {
      // WEB: Only use remote datasource
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.getById(id);
        return Right(remoteItem);
      }

      // NATIVE: Use offline-first strategy
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.getById(id);

          // Sync related product first
          if (remoteItem.product != null) {
            await productLocalDataSource!.upsert(remoteItem.product!);
          }

          await localDataSource!.insert(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          final localItem = await localDataSource!.getById(id);
          return Right(localItem);
        }
      } else {
        final localItem = await localDataSource!.getById(id);
        return Right(localItem);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> create(ProductEntry productEntry) async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final newEntry = productEntry.copyWith(
        id: const Uuid().v4(),
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WEB: Only create on remote
      if (PlatformInfo.isWeb) {
        final remoteEntry = await remoteDataSource.create(newEntry);
        return Right(remoteEntry);
      }

      // NATIVE: Offline-first
      await localDataSource!.insert(newEntry);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteEntry = await remoteDataSource.create(newEntry);
          await localDataSource!.update(remoteEntry);
          await localDataSource!.markAsSynced(remoteEntry.id);
          return Right(remoteEntry);
        } catch (e) {
          // If remote create fails, mark as not synced
          final unsyncedEntry = newEntry.copyWith(synced: false);
          await localDataSource!.update(unsyncedEntry);
          return Right(unsyncedEntry);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedEntry = newEntry.copyWith(synced: false);
        await localDataSource!.update(unsyncedEntry);
        return Right(unsyncedEntry);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> update(ProductEntry productEntry) async {
    try {
      final updatedEntry = productEntry.copyWith(
        updatedAt: DateTime.now(),
      );

      // WEB: Only update on remote
      if (PlatformInfo.isWeb) {
        final remoteEntry = await remoteDataSource.update(updatedEntry);
        return Right(remoteEntry);
      }

      // NATIVE: Offline-first
      await localDataSource!.update(updatedEntry);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteEntry = await remoteDataSource.update(updatedEntry);
          await localDataSource!.update(remoteEntry);
          await localDataSource!.markAsSynced(remoteEntry.id);
          return Right(remoteEntry);
        } catch (e) {
          // If remote update fails, mark as not synced
          final unsyncedEntry = updatedEntry.copyWith(synced: false);
          await localDataSource!.update(unsyncedEntry);
          return Right(unsyncedEntry);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedEntry = updatedEntry.copyWith(synced: false);
        await localDataSource!.update(unsyncedEntry);
        return Right(unsyncedEntry);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      // WEB: Only delete on remote
      if (PlatformInfo.isWeb) {
        await remoteDataSource.delete(id);
        return const Right(null);
      }

      // NATIVE: Offline-first
      await localDataSource!.delete(id);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
        } catch (e) {
          // If remote delete fails, the item will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sync() async {
    try {
      // WEB: No sync needed (online-only mode, no local database)
      if (PlatformInfo.isWeb || localDataSource == null) {
        return const Right(null);
      }

      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await localDataSource!.getUnsynced();

      for (var item in unsyncedItems) {
        try {
          // Check if item exists on server by trying to get it
          ProductEntry? remoteItem;
          try {
            remoteItem = await remoteDataSource.getById(item.id);
          } catch (e) {
            // Item doesn't exist on server, will create it
            remoteItem = null;
          }

          if (remoteItem != null) {
            // Item exists on server, update it
            await remoteDataSource.update(item);
          } else {
            // Item doesn't exist on server, create it
            await remoteDataSource.create(item);
          }

          // Mark as synced only after successful operation
          await localDataSource!.markAsSynced(item.id);
        } catch (e) {
          // If sync fails for this item, continue with next item
          // The item will remain unsynced and will be retried in next sync
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
