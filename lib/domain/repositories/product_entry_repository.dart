import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/product_entry.dart';
import '../models/paginated_result.dart';

abstract class ProductEntryRepository {
  Future<Either<Failure, List<ProductEntry>>> getAll();
  Future<Either<Failure, PaginatedResult<ProductEntry>>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<Either<Failure, List<ProductEntry>>> getByProductId(String productId);
  Future<Either<Failure, ProductEntry>> getById(String id);
  Future<Either<Failure, ProductEntry>> create(ProductEntry productEntry);
  Future<Either<Failure, ProductEntry>> update(ProductEntry productEntry);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> sync();
}
