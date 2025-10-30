import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getAll({bool includeInactive = false}) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getAll(includeInactive: includeInactive);
          // Use upsert to merge remote data with local data efficiently
          await localDataSource.upsertAll(remoteItems);
          // Mark all as synced
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getAll(includeInactive: includeInactive);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getAll(includeInactive: includeInactive);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Product>>> getPaginated({
    required int page,
    required int pageSize,
    bool includeInactive = false,
  }) async {
    try {
      final isConnected = await networkInfo.isConnected;

      // Sync from server on first page when connected
      if (isConnected && page == 1) {
        try {
          final remoteItems = await remoteDataSource.getAll(includeInactive: includeInactive);
          await localDataSource.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }
        } catch (e) {
          // Continue with local data if sync fails
        }
      }

      final result = await localDataSource.getPaginated(
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
  Future<Either<Failure, Product>> getById(String id) async {
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

      return const Left(CacheFailure('Product not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getByCode(String code) async {
    try {
      final localItem = await localDataSource.getByCode(code);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getByCode(code);
        await localDataSource.insert(remoteItem);
        await localDataSource.markAsSynced(remoteItem.id);
        return Right(remoteItem);
      }

      return const Left(CacheFailure('Product not found'));
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.create(newItem);
          await localDataSource.insert(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          await localDataSource.insert(newItem);
          return Right(newItem);
        }
      } else {
        await localDataSource.insert(newItem);
        return Right(newItem);
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.update(updatedItem);
          await localDataSource.update(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          await localDataSource.update(updatedItem);
          return Right(updatedItem);
        }
      } else {
        await localDataSource.update(updatedItem);
        return Right(updatedItem);
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
}
