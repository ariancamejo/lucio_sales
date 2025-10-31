import 'package:equatable/equatable.dart';
import '../../../domain/entities/measurement_unit.dart';

abstract class MeasurementUnitState extends Equatable {
  const MeasurementUnitState();

  @override
  List<Object> get props => [];
}

class MeasurementUnitInitial extends MeasurementUnitState {}

class MeasurementUnitLoading extends MeasurementUnitState {}

class MeasurementUnitLoaded extends MeasurementUnitState {
  final List<MeasurementUnit> measurementUnits;

  const MeasurementUnitLoaded(this.measurementUnits);

  @override
  List<Object> get props => [measurementUnits];
}

class MeasurementUnitPaginatedLoaded extends MeasurementUnitState {
  final List<MeasurementUnit> measurementUnits;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;

  const MeasurementUnitPaginatedLoaded({
    required this.measurementUnits,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
  });

  @override
  List<Object> get props => [measurementUnits, currentPage, totalPages, totalItems, pageSize];
}

class MeasurementUnitError extends MeasurementUnitState {
  final String message;

  const MeasurementUnitError(this.message);

  @override
  List<Object> get props => [message];
}

class MeasurementUnitOperationSuccess extends MeasurementUnitState {
  final String message;

  const MeasurementUnitOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
