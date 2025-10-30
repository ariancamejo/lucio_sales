import 'package:equatable/equatable.dart';
import '../../../domain/entities/measurement_unit.dart';

abstract class MeasurementUnitEvent extends Equatable {
  const MeasurementUnitEvent();

  @override
  List<Object> get props => [];
}

class LoadMeasurementUnits extends MeasurementUnitEvent {}

class LoadMeasurementUnitsPaginated extends MeasurementUnitEvent {
  final int page;
  final int pageSize;

  const LoadMeasurementUnitsPaginated({
    required this.page,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [page, pageSize];
}

class CreateMeasurementUnit extends MeasurementUnitEvent {
  final MeasurementUnit measurementUnit;

  const CreateMeasurementUnit(this.measurementUnit);

  @override
  List<Object> get props => [measurementUnit];
}

class UpdateMeasurementUnit extends MeasurementUnitEvent {
  final MeasurementUnit measurementUnit;

  const UpdateMeasurementUnit(this.measurementUnit);

  @override
  List<Object> get props => [measurementUnit];
}

class DeleteMeasurementUnit extends MeasurementUnitEvent {
  final String id;

  const DeleteMeasurementUnit(this.id);

  @override
  List<Object> get props => [id];
}
