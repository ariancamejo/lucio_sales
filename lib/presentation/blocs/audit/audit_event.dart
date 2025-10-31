import 'package:equatable/equatable.dart';

abstract class AuditEvent extends Equatable {
  const AuditEvent();

  @override
  List<Object?> get props => [];
}

class LoadAuditHistory extends AuditEvent {
  final int? limit;

  const LoadAuditHistory({this.limit});

  @override
  List<Object?> get props => [limit];
}

class LoadAuditHistoryForUser extends AuditEvent {
  final String userId;
  final int? limit;

  const LoadAuditHistoryForUser({required this.userId, this.limit});

  @override
  List<Object?> get props => [userId, limit];
}

class LoadAuditHistoryForEntity extends AuditEvent {
  final String entityType;
  final String entityId;

  const LoadAuditHistoryForEntity({
    required this.entityType,
    required this.entityId,
  });

  @override
  List<Object?> get props => [entityType, entityId];
}

class FilterAuditHistory extends AuditEvent {
  final String? entityType;
  final String? action;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterAuditHistory({
    this.entityType,
    this.action,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [entityType, action, startDate, endDate];
}

class LoadAuditHistoryPaginated extends AuditEvent {
  final int page;
  final int pageSize;
  final String? entityType;
  final String? action;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? synced;

  const LoadAuditHistoryPaginated({
    required this.page,
    required this.pageSize,
    this.entityType,
    this.action,
    this.startDate,
    this.endDate,
    this.synced,
  });

  @override
  List<Object?> get props => [page, pageSize, entityType, action, startDate, endDate, synced];
}
