import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../domain/entities/user_history.dart';
import '../../domain/repositories/user_history_repository.dart';
import '../datasources/local/user_history_local_datasource.dart';
import '../datasources/remote/user_history_remote_datasource.dart';

class UserHistoryRepositoryImpl implements UserHistoryRepository {
  final UserHistoryRemoteDataSource remoteDataSource;
  final UserHistoryLocalDataSource? localDataSource;
  final NetworkInfo networkInfo;

  UserHistoryRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<UserHistory>>> getAll({String? userId}) async {
    try {
      // WEB: Only use remote datasource (online-only)
      if (PlatformInfo.isWeb) {
        final remoteItems = await remoteDataSource.getAll(userId: userId);
        return Right(remoteItems);
      }

      // NATIVE: Use offline-first strategy with local database
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll(userId: userId);
          final localItems = await localDataSource!.getAll(userId: userId);

          // Get items that have pending changes (not synced)
          final unsyncedIds = localItems
              .where((item) => !item.synced)
              .map((item) => item.id)
              .toSet();

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

          // Return merged list: remote items + unsynced local items
          final allItems = await localDataSource!.getAll(userId: userId);
          return Right(allItems);
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
  Future<Either<Failure, UserHistory>> getById(String id) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.getById(id);
        return Right(remoteItem);
      }

      // NATIVE: Try local first, then remote
      final localItem = await localDataSource!.getById(id);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getById(id);
        await localDataSource!.upsert(remoteItem);
        return Right(remoteItem);
      }

      return const Left(CacheFailure('Item not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserHistory>> create(UserHistory history) async {
    try {
      // WEB: Only create on remote
      if (PlatformInfo.isWeb) {
        final remoteHistory = await remoteDataSource.create(history);
        return Right(remoteHistory);
      }

      // NATIVE: Offline-first
      // Always save locally first
      final localHistory = history.copyWith(synced: false);
      await localDataSource!.insert(localHistory);
      print('📝 Audit inserted locally with synced=false');

      // Try to sync with server
      final isConnected = await networkInfo.isConnected;
      print('🌐 Network connected: $isConnected');

      if (isConnected) {
        try {
          print('🚀 Attempting to sync audit to Supabase...');
          final remoteHistory = await remoteDataSource.create(history);
          print('✅ Supabase sync successful, updating local with synced=true');
          await localDataSource!.upsert(remoteHistory);
          return Right(remoteHistory);
        } catch (e) {
          print('❌ Supabase sync failed: $e');
          // Return local version if remote fails
          return Right(localHistory);
        }
      }

      print('⚠️ No connection, returning local version');
      return Right(localHistory);
    } catch (e) {
      print('💥 Repository error: $e');
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
      // Delete locally first
      await localDataSource!.delete(id);

      // Try to delete from server
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
        } catch (e) {
          // Ignore remote delete errors
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncToRemote() async {
    try {
      // WEB: No sync needed (online-only mode, no local database)
      if (PlatformInfo.isWeb || localDataSource == null) {
        return const Right(null);
      }

      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return const Left(ServerFailure('No internet connection'));
      }

      // Get all unsynced items
      final unsyncedItems = await localDataSource!.getUnsyncedItems();

      // Sync each item
      for (var item in unsyncedItems) {
        try {
          // UserHistory is append-only, so we only create, never update
          // Check if item exists on server to avoid duplicates
          try {
            await remoteDataSource.getById(item.id);
            // If it exists, just mark as synced
            await localDataSource!.markAsSynced(item.id);
          } catch (e) {
            // Item doesn't exist on server, create it
            await remoteDataSource.create(item);
            await localDataSource!.markAsSynced(item.id);
          }
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
