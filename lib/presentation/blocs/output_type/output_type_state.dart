import 'package:equatable/equatable.dart';
import '../../../domain/entities/output_type.dart';

abstract class OutputTypeState extends Equatable {
  const OutputTypeState();

  @override
  List<Object> get props => [];
}

class OutputTypeInitial extends OutputTypeState {}

class OutputTypeLoading extends OutputTypeState {}

class OutputTypeLoaded extends OutputTypeState {
  final List<OutputType> outputTypes;

  const OutputTypeLoaded(this.outputTypes);

  @override
  List<Object> get props => [outputTypes];
}

class OutputTypePaginatedLoaded extends OutputTypeState {
  final List<OutputType> outputTypes;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;

  const OutputTypePaginatedLoaded({
    required this.outputTypes,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
  });

  @override
  List<Object> get props => [outputTypes, currentPage, totalPages, totalItems, pageSize];
}

class OutputTypeError extends OutputTypeState {
  final String message;

  const OutputTypeError(this.message);

  @override
  List<Object> get props => [message];
}

class OutputTypeOperationSuccess extends OutputTypeState {
  final String message;

  const OutputTypeOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
