import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/output.dart';
import '../models/paginated_result.dart';

abstract class OutputRepository {
  Future<Either<Failure, List<Output>>> getAll();
  Future<Either<Failure, PaginatedResult<Output>>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<Either<Failure, Output>> getById(String id);
  Future<Either<Failure, List<Output>>> getByDateRange(DateTime start, DateTime end);
  Future<Either<Failure, List<Output>>> getByType(String outputTypeId);
  Future<Either<Failure, Output>> create(Output output);
  Future<Either<Failure, Output>> update(Output output);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> sync();

  // Reports
  Future<Either<Failure, Map<String, dynamic>>> getSalesByDay(DateTime date);
  Future<Either<Failure, Map<String, dynamic>>> getSalesByMonth(int year, int month);
  Future<Either<Failure, Map<String, dynamic>>> getSalesByYear(int year);
  Future<Either<Failure, List<Map<String, dynamic>>>> getIPVReport();
}
