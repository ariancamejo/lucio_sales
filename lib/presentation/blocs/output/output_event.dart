import 'package:equatable/equatable.dart';
import '../../../domain/entities/output.dart';

abstract class OutputEvent extends Equatable {
  const OutputEvent();

  @override
  List<Object?> get props => [];
}

class LoadOutputs extends OutputEvent {}

class LoadOutputsPaginated extends OutputEvent {
  final int page;
  final int pageSize;

  const LoadOutputsPaginated({
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [page, pageSize];
}

class LoadOutputsByDateRange extends OutputEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadOutputsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class LoadOutputsByType extends OutputEvent {
  final String outputTypeId;

  const LoadOutputsByType(this.outputTypeId);

  @override
  List<Object?> get props => [outputTypeId];
}

class CreateOutput extends OutputEvent {
  final Output output;

  const CreateOutput(this.output);

  @override
  List<Object?> get props => [output];
}

class UpdateOutput extends OutputEvent {
  final Output output;

  const UpdateOutput(this.output);

  @override
  List<Object?> get props => [output];
}

class DeleteOutput extends OutputEvent {
  final String id;

  const DeleteOutput(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadSalesByDay extends OutputEvent {
  final DateTime date;

  const LoadSalesByDay(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadSalesByMonth extends OutputEvent {
  final int year;
  final int month;

  const LoadSalesByMonth(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}

class LoadSalesByYear extends OutputEvent {
  final int year;

  const LoadSalesByYear(this.year);

  @override
  List<Object?> get props => [year];
}

class LoadIPVReport extends OutputEvent {}

class SearchAndFilterOutputs extends OutputEvent {
  final String? searchQuery; // Search by product name
  final DateTime? startDate;
  final DateTime? endDate;
  final String? outputTypeId;
  final double? minQuantity;
  final double? maxQuantity;
  final double? minAmount;
  final double? maxAmount;

  const SearchAndFilterOutputs({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.outputTypeId,
    this.minQuantity,
    this.maxQuantity,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [
        searchQuery,
        startDate,
        endDate,
        outputTypeId,
        minQuantity,
        maxQuantity,
        minAmount,
        maxAmount,
      ];
}
