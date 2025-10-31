import 'package:equatable/equatable.dart';
import '../../../core/database/app_database.dart';

abstract class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {}

class AuditLoading extends AuditState {}

class AuditLoaded extends AuditState {
  final List<UserHistoryData> history;

  const AuditLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AuditError extends AuditState {
  final String message;

  const AuditError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuditPaginatedLoaded extends AuditState {
  final List<UserHistoryData> history;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const AuditPaginatedLoaded({
    required this.history,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  @override
  List<Object?> get props => [history, currentPage, totalPages, totalItems];
}
