import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../domain/entities/output.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/output_repository.dart';
import '../datasources/local/output_local_datasource.dart';
import '../datasources/remote/output_remote_datasource.dart';
import 'base/base_offline_first_repository.dart';

class OutputRepositoryImpl extends BaseOfflineFirstRepository<Output, OutputRemoteDataSource, OutputLocalDataSource>
    implements OutputRepository {

  OutputRepositoryImpl({
    required OutputRemoteDataSource remoteDataSource,
    OutputLocalDataSource? localDataSource,
    required NetworkInfo networkInfo,
  }) : super(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
          networkInfo: networkInfo,
        );

  // ========== Implementation of abstract methods from base class ==========

  @override
  String getEntityId(Output entity) => entity.id;

  @override
  bool isEntitySynced(Output entity) => entity.synced;

  @override
  bool hasDataChanges(Output local, Output remote) => local.hasDataChanges(remote);

  @override
  Future<List<Output>> getAllFromRemote() => remoteDataSource.getAll();

  @override
  Future<List<Output>> getAllFromLocal() => localDataSource!.getAll();

  @override
  Future<Output> getByIdFromRemote(String id) => remoteDataSource.getById(id);

  @override
  Future<Output?> getByIdFromLocal(String id) => localDataSource!.getById(id);

  @override
  Future<Output> createOnRemote(Output item) => remoteDataSource.create(item);

  @override
  Future<Output> updateOnRemote(Output item) => remoteDataSource.update(item);

  @override
  Future<void> deleteFromRemote(String id) => remoteDataSource.delete(id);

  @override
  Future<void> upsertAllToLocal(List<Output> items) => localDataSource!.upsertAll(items);

  @override
  Future<void> deleteFromLocal(String id) => localDataSource!.delete(id);

  @override
  Future<List<Output>> getUnsyncedFromLocal() => localDataSource!.getUnsyncedItems();

  @override
  Future<void> markAsSyncedInLocal(String id) => localDataSource!.markAsSynced(id);

  // ========== Repository methods ==========

  @override
  Future<Either<Failure, List<Output>>> getAll() {
    // Use base implementation
    return baseGetAll();
  }

  @override
  Future<Either<Failure, PaginatedResult<Output>>> getPaginated({
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

      // NATIVE: Always fetch from local database for fast response
      final result = await localDataSource!.getPaginated(
        page: page,
        pageSize: pageSize,
      );

      // Sync happens in background via SyncBloc, not during pagination
      // This makes pagination much faster and less resource intensive

      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Output>> getById(String id) async {
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
        await localDataSource!.insert(remoteItem);
        await localDataSource!.markAsSynced(remoteItem.id);
        return Right(remoteItem);
      }

      return const Left(CacheFailure('Item not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Output>>> getByDateRange(DateTime start, DateTime end) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItems = await remoteDataSource.getByDateRange(start, end);
        return Right(remoteItems);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByDateRange(start, end);
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource!.getByDateRange(start, end);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource!.getByDateRange(start, end);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Output>>> getByType(String outputTypeId) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItems = await remoteDataSource.getByType(outputTypeId);
        return Right(remoteItems);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByType(outputTypeId);
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource!.getByType(outputTypeId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource!.getByType(outputTypeId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Output>> create(Output output) async {
    try {
      final newItem = output.copyWith(
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
  Future<Either<Failure, Output>> update(Output output) async {
    try {
      final updatedItem = output.copyWith(
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

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      // WEB: Only delete on remote
      if (PlatformInfo.isWeb) {
        await remoteDataSource.delete(id);
        return const Right(null);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
          await localDataSource!.delete(id);
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
          await localDataSource!.delete(id);
          return const Right(null);
        }
      } else {
        await localDataSource!.delete(id);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
        return const Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await localDataSource!.getUnsyncedItems();

      for (var item in unsyncedItems) {
        try {
          // Check if item exists on server by trying to get it
          Output? remoteItem;
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
      return Left(SyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSalesByDay(DateTime date) async {
    try {
      // WEB: Only use remote (reports are always online)
      if (PlatformInfo.isWeb) {
        final report = await remoteDataSource.getSalesByDay(date);
        return Right(report);
      }

      // NATIVE: Reports require internet connection
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final report = await remoteDataSource.getSalesByDay(date);
          return Right(report);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return const Left(NetworkFailure('Reports require internet connection'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSalesByMonth(int year, int month) async {
    try {
      // WEB: Only use remote (reports are always online)
      if (PlatformInfo.isWeb) {
        final report = await remoteDataSource.getSalesByMonth(year, month);
        return Right(report);
      }

      // NATIVE: Reports require internet connection
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final report = await remoteDataSource.getSalesByMonth(year, month);
          return Right(report);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return const Left(NetworkFailure('Reports require internet connection'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSalesByYear(int year) async {
    try {
      // WEB: Only use remote (reports are always online)
      if (PlatformInfo.isWeb) {
        final report = await remoteDataSource.getSalesByYear(year);
        return Right(report);
      }

      // NATIVE: Reports require internet connection
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final report = await remoteDataSource.getSalesByYear(year);
          return Right(report);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return const Left(NetworkFailure('Reports require internet connection'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getIPVReport() async {
    try {
      // WEB: Only use remote (reports are always online)
      if (PlatformInfo.isWeb) {
        final report = await remoteDataSource.getIPVReport();
        return Right(report);
      }

      // NATIVE: Reports require internet connection
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final report = await remoteDataSource.getIPVReport();
          return Right(report);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return const Left(NetworkFailure('Reports require internet connection'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
