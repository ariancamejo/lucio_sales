import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/output_type.dart';
import '../models/paginated_result.dart';

abstract class OutputTypeRepository {
  Future<Either<Failure, List<OutputType>>> getAll();
  Future<Either<Failure, PaginatedResult<OutputType>>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<Either<Failure, OutputType>> getById(String id);
  Future<Either<Failure, OutputType>> create(OutputType outputType);
  Future<Either<Failure, OutputType>> update(OutputType outputType);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> sync();
}
