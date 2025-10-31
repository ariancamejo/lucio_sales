import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user_history.dart';
import '../../domain/repositories/user_history_repository.dart';
import '../datasources/local/user_history_local_datasource.dart';
import '../datasources/remote/user_history_remote_datasource.dart';

class UserHistoryRepositoryImpl implements UserHistoryRepository {
  final UserHistoryRemoteDataSource remoteDataSource;
  final UserHistoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserHistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<UserHistory>>> getAll({String? userId}) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll(userId: userId);
          final localItems = await localDataSource.getAll(userId: userId);

          // Upsert remote items (they come with synced=true)
          await localDataSource.upsertAll(remoteItems);

          // Find local items that are NOT in remote and were previously synced
          // Only delete items with synced=true that are no longer on server
          // Keep items with synced=false (they're pending sync)
          final remoteIds = remoteItems.map((item) => item.id).toSet();
          for (var localItem in localItems) {
            if (!remoteIds.contains(localItem.id) && localItem.synced) {
              await localDataSource.delete(localItem.id);
            }
          }

          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getAll(userId: userId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getAll(userId: userId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserHistory>> getById(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.getById(id);
          await localDataSource.upsert(remoteItem);
          return Right(remoteItem);
        } catch (e) {
          final localItem = await localDataSource.getById(id);
          if (localItem != null) {
            return Right(localItem);
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        final localItem = await localDataSource.getById(id);
        if (localItem != null) {
          return Right(localItem);
        }
        return const Left(CacheFailure('No data available offline'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserHistory>> create(UserHistory history) async {
    try {
      // Always save locally first
      final localHistory = history.copyWith(synced: false);
      await localDataSource.insert(localHistory);
      print('📝 Audit inserted locally with synced=false');

      // Try to sync with server
      final isConnected = await networkInfo.isConnected;
      print('🌐 Network connected: $isConnected');

      if (isConnected) {
        try {
          print('🚀 Attempting to sync audit to Supabase...');
          final remoteHistory = await remoteDataSource.create(history);
          print('✅ Supabase sync successful, updating local with synced=true');
          await localDataSource.upsert(remoteHistory);
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
      // Delete locally first
      await localDataSource.delete(id);

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
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return const Left(ServerFailure('No internet connection'));
      }

      // Get all unsynced items
      final unsyncedItems = await localDataSource.getUnsyncedItems();

      // Sync each item
      for (var item in unsyncedItems) {
        try {
          await remoteDataSource.create(item);
          await localDataSource.markAsSynced(item.id);
        } catch (e) {
          // Continue with next item if one fails
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
