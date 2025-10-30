import 'package:equatable/equatable.dart';
import '../../../domain/entities/output.dart';

abstract class OutputState extends Equatable {
  const OutputState();

  @override
  List<Object> get props => [];
}

class OutputInitial extends OutputState {}

class OutputLoading extends OutputState {}

class OutputLoaded extends OutputState {
  final List<Output> outputs;

  const OutputLoaded(this.outputs);

  @override
  List<Object> get props => [outputs];
}

class OutputPaginatedLoaded extends OutputState {
  final List<Output> outputs;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const OutputPaginatedLoaded({
    required this.outputs,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  @override
  List<Object> get props => [outputs, currentPage, totalPages, totalItems];
}

class OutputError extends OutputState {
  final String message;

  const OutputError(this.message);

  @override
  List<Object> get props => [message];
}

class OutputOperationSuccess extends OutputState {
  final String message;

  const OutputOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ReportLoaded extends OutputState {
  final Map<String, dynamic> report;

  const ReportLoaded(this.report);

  @override
  List<Object> get props => [report];
}

class IPVReportLoaded extends OutputState {
  final List<Map<String, dynamic>> report;

  const IPVReportLoaded(this.report);

  @override
  List<Object> get props => [report];
}
