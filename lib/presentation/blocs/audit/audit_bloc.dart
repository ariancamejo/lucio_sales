import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/audit_service.dart';
import 'audit_event.dart';
import 'audit_state.dart';

class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AuditService auditService;

  AuditBloc({required this.auditService}) : super(AuditInitial()) {
    on<LoadAuditHistory>(_onLoadAuditHistory);
    on<LoadAuditHistoryForUser>(_onLoadAuditHistoryForUser);
    on<LoadAuditHistoryForEntity>(_onLoadAuditHistoryForEntity);
    on<FilterAuditHistory>(_onFilterAuditHistory);
    on<LoadAuditHistoryPaginated>(_onLoadAuditHistoryPaginated);
  }

  Future<void> _onLoadAuditHistory(
    LoadAuditHistory event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final history = await auditService.getAllHistory(limit: event.limit);
      emit(AuditLoaded(history));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  Future<void> _onLoadAuditHistoryForUser(
    LoadAuditHistoryForUser event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final history = await auditService.getHistoryForUser(
        userId: event.userId,
        limit: event.limit,
      );
      emit(AuditLoaded(history));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  Future<void> _onLoadAuditHistoryForEntity(
    LoadAuditHistoryForEntity event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final history = await auditService.getHistoryForEntity(
        entityType: event.entityType,
        entityId: event.entityId,
      );
      emit(AuditLoaded(history));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  Future<void> _onFilterAuditHistory(
    FilterAuditHistory event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      // Get all history first
      var history = await auditService.getAllHistory();

      // Apply filters
      if (event.entityType != null) {
        history = history
            .where((item) => item.entityType == event.entityType)
            .toList();
      }

      if (event.action != null) {
        history = history
            .where((item) => item.action == event.action)
            .toList();
      }

      if (event.startDate != null) {
        history = history
            .where((item) =>
                item.timestamp.isAfter(event.startDate!) ||
                item.timestamp.isAtSameMomentAs(event.startDate!))
            .toList();
      }

      if (event.endDate != null) {
        final endOfDay = DateTime(
          event.endDate!.year,
          event.endDate!.month,
          event.endDate!.day,
          23,
          59,
          59,
        );
        history = history
            .where((item) =>
                item.timestamp.isBefore(endOfDay) ||
                item.timestamp.isAtSameMomentAs(endOfDay))
            .toList();
      }

      emit(AuditLoaded(history));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }

  Future<void> _onLoadAuditHistoryPaginated(
    LoadAuditHistoryPaginated event,
    Emitter<AuditState> emit,
  ) async {
    emit(AuditLoading());
    try {
      final result = await auditService.getHistoryPaginated(
        page: event.page,
        pageSize: event.pageSize,
        entityType: event.entityType,
        action: event.action,
        startDate: event.startDate,
        endDate: event.endDate,
        synced: event.synced,
      );

      final items = result['items'] as List;
      emit(AuditPaginatedLoaded(
        history: items.cast<UserHistoryData>(),
        currentPage: result['page'] as int,
        totalPages: result['totalPages'] as int,
        totalItems: result['totalCount'] as int,
      ));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }
}
