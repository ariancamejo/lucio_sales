import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/platform/platform_info.dart';

/// Base class for offline-first repositories
/// Provides common sync logic that can be reused across all repositories
///
/// Type Parameters:
/// - T: The entity type (e.g., Product, OutputType)
/// - R: The remote datasource type
/// - L: The local datasource type
abstract class BaseOfflineFirstRepository<T, R, L> {
  final R remoteDataSource;
  final L? localDataSource;
  final NetworkInfo networkInfo;

  BaseOfflineFirstRepository({
    required this.remoteDataSource,
    this.localDataSource,
    required this.networkInfo,
  });

  // ========== Abstract methods that must be implemented by subclasses ==========

  /// Gets the ID from an entity
  String getEntityId(T entity);

  /// Checks if an entity is synced
  bool isEntitySynced(T entity);

  /// Compares business data between two entities (excluding id, timestamps, synced status)
  /// Returns true if the entities have different data
  /// This is used to determine if a local unsynced item has real changes vs just being old
  bool hasDataChanges(T local, T remote);

  /// Gets all items from remote datasource
  Future<List<T>> getAllFromRemote();

  /// Gets all items from local datasource
  Future<List<T>> getAllFromLocal();

  /// Gets an item by ID from remote datasource
  Future<T> getByIdFromRemote(String id);

  /// Gets an item by ID from local datasource
  Future<T?> getByIdFromLocal(String id);

  /// Creates an item on remote datasource
  Future<T> createOnRemote(T item);

  /// Updates an item on remote datasource
  Future<T> updateOnRemote(T item);

  /// Deletes an item from remote datasource
  Future<void> deleteFromRemote(String id);

  /// Upserts multiple items to local datasource
  Future<void> upsertAllToLocal(List<T> items);

  /// Deletes an item from local datasource
  Future<void> deleteFromLocal(String id);

  /// Gets all unsynced items from local datasource
  Future<List<T>> getUnsyncedFromLocal();

  /// Marks an item as synced in local datasource
  Future<void> markAsSyncedInLocal(String id);

  // ========== Common implementation methods ==========

  /// Common getAll implementation with offline-first strategy
  /// Preserves local unsynced changes while syncing remote data
  Future<Either<Failure, List<T>>> baseGetAll() async {
    try {
      // WEB: Only use remote datasource (online-only)
      if (PlatformInfo.isWeb) {
        final remoteItems = await getAllFromRemote();
        return Right(remoteItems);
      }

      // NATIVE: Use offline-first strategy with local database
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Get remote and local items
          final remoteItems = await getAllFromRemote();
          final localItems = await getAllFromLocal();

          // Build a map of local items by ID for quick lookup
          final localItemsMap = {for (var item in localItems) getEntityId(item): item};

          // Determine which items have REAL local changes (not just synced=false)
          // An item has real changes if:
          // 1. It has synced=false AND
          // 2. Its data is different from the server (using hasDataChanges method)
          final itemsWithRealChanges = <String>{};
          for (var remoteItem in remoteItems) {
            final localItem = localItemsMap[getEntityId(remoteItem)];
            if (localItem != null && !isEntitySynced(localItem)) {
              // Use the hasDataChanges method to compare business data
              if (hasDataChanges(localItem, remoteItem)) {
                itemsWithRealChanges.add(getEntityId(localItem));
              }
            }
          }

          // Only upsert remote items that don't have real local changes
          final itemsToUpsert = remoteItems
              .where((item) => !itemsWithRealChanges.contains(getEntityId(item)))
              .toList();

          await upsertAllToLocal(itemsToUpsert);

          // Find local items that are NOT in remote and were previously synced
          // Delete them as they were deleted from another device
          // Keep items with synced=false (they're pending sync)
          final remoteIds = remoteItems.map((item) => getEntityId(item)).toSet();
          for (var localItem in localItems) {
            if (!remoteIds.contains(getEntityId(localItem)) && isEntitySynced(localItem)) {
              await deleteFromLocal(getEntityId(localItem));
            }
          }

          // Return merged list: remote items + unsynced local items
          final allItems = await getAllFromLocal();
          return Right(allItems);
        } catch (e) {
          final localItems = await getAllFromLocal();
          return Right(localItems);
        }
      } else {
        final localItems = await getAllFromLocal();
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Common sync implementation
  /// Distinguishes between creating new items and updating existing ones
  Future<Either<Failure, void>> baseSync() async {
    try {
      // WEB: No sync needed (online-only mode, no local database)
      if (PlatformInfo.isWeb || localDataSource == null) {
        return const Right(null);
      }

      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await getUnsyncedFromLocal();

      for (var item in unsyncedItems) {
        try {
          // Check if item exists on server by trying to get it
          T? remoteItem;
          try {
            remoteItem = await getByIdFromRemote(getEntityId(item));
          } catch (e) {
            // Item doesn't exist on server, will create it
            remoteItem = null;
          }

          if (remoteItem != null) {
            // Item exists on server, update it
            await updateOnRemote(item);
          } else {
            // Item doesn't exist on server, create it
            await createOnRemote(item);
          }

          // Mark as synced only after successful operation
          await markAsSyncedInLocal(getEntityId(item));
        } catch (e) {
          // If sync fails for this item, continue with next item
          // The item will remain unsynced and will be retried in next sync
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(e.toString()));
    }
  }

  /// Common getById implementation with offline-first strategy
  Future<Either<Failure, T>> baseGetById(String id) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await getByIdFromRemote(id);
        return Right(remoteItem);
      }

      // NATIVE: Try local first, then remote
      final localItem = await getByIdFromLocal(id);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await getByIdFromRemote(id);
        await upsertAllToLocal([remoteItem]);
        await markAsSyncedInLocal(id);
        return Right(remoteItem);
      }

      return const Left(CacheFailure('Item not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Common delete implementation with offline-first strategy
  Future<Either<Failure, void>> baseDelete(String id) async {
    try {
      // WEB: Only delete on remote
      if (PlatformInfo.isWeb) {
        await deleteFromRemote(id);
        return const Right(null);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await deleteFromRemote(id);
          await deleteFromLocal(id);
          return const Right(null);
        } catch (e) {
          // If the error is about constraint violation, don't delete locally
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('cannot delete') ||
              errorMessage.contains('is being used') ||
              errorMessage.contains('foreign key') ||
              errorMessage.contains('constraint')) {
            return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
          }

          // For other errors, delete locally and sync later
          await deleteFromLocal(id);
          return const Right(null);
        }
      } else {
        await deleteFromLocal(id);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
