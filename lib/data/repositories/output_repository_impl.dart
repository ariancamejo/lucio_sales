import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/output.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/output_repository.dart';
import '../datasources/local/output_local_datasource.dart';
import '../datasources/remote/output_remote_datasource.dart';

class OutputRepositoryImpl implements OutputRepository {
  final OutputRemoteDataSource remoteDataSource;
  final OutputLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  OutputRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Output>>> getAll() async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll();
          final localItems = await localDataSource.getAll();

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
          final localItems = await localDataSource.getAll();
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getAll();
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Output>>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;

      // Sync from server on first page when connected
      if (isConnected && page == 1) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll();
          final localItems = await localDataSource.getAll();

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
        } catch (e) {
          // Continue with local data if sync fails
        }
      }

      final result = await localDataSource.getPaginated(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Output>> getById(String id) async {
    try {
      final localItem = await localDataSource.getById(id);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getById(id);
        await localDataSource.insert(remoteItem);
        await localDataSource.markAsSynced(remoteItem.id);
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
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByDateRange(start, end);
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getByDateRange(start, end);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getByDateRange(start, end);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Output>>> getByType(String outputTypeId) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByType(outputTypeId);
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getByType(outputTypeId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getByType(outputTypeId);
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.create(newItem);
          await localDataSource.insert(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote create fails, mark as not synced
          final unsyncedItem = newItem.copyWith(synced: false);
          await localDataSource.insert(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = newItem.copyWith(synced: false);
        await localDataSource.insert(unsyncedItem);
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.update(updatedItem);
          await localDataSource.update(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote update fails, mark as not synced
          final unsyncedItem = updatedItem.copyWith(synced: false);
          await localDataSource.update(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = updatedItem.copyWith(synced: false);
        await localDataSource.update(unsyncedItem);
        return Right(unsyncedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
          await localDataSource.delete(id);
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
          await localDataSource.delete(id);
          return const Right(null);
        }
      } else {
        await localDataSource.delete(id);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sync() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await localDataSource.getUnsyncedItems();

      for (var item in unsyncedItems) {
        try {
          await remoteDataSource.create(item);
          await localDataSource.markAsSynced(item.id);
        } catch (e) {
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
