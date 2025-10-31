import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/measurement_unit_repository.dart';
import 'measurement_unit_event.dart';
import 'measurement_unit_state.dart';

class MeasurementUnitBloc extends Bloc<MeasurementUnitEvent, MeasurementUnitState> {
  final MeasurementUnitRepository repository;

  MeasurementUnitBloc({required this.repository}) : super(MeasurementUnitInitial()) {
    on<LoadMeasurementUnits>(_onLoadMeasurementUnits);
    on<LoadMeasurementUnitsPaginated>(_onLoadMeasurementUnitsPaginated);
    on<CreateMeasurementUnit>(_onCreateMeasurementUnit);
    on<UpdateMeasurementUnit>(_onUpdateMeasurementUnit);
    on<DeleteMeasurementUnit>(_onDeleteMeasurementUnit);
  }

  Future<void> _onLoadMeasurementUnits(
    LoadMeasurementUnits event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    emit(MeasurementUnitLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(MeasurementUnitError(failure.message)),
      (measurementUnits) => emit(MeasurementUnitLoaded(measurementUnits)),
    );
  }

  Future<void> _onLoadMeasurementUnitsPaginated(
    LoadMeasurementUnitsPaginated event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    emit(MeasurementUnitLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
    );
    result.fold(
      (failure) => emit(MeasurementUnitError(failure.message)),
      (paginatedResult) {
        // If current page is empty and not the first page, go to previous page
        if (paginatedResult.items.isEmpty && event.page > 1) {
          add(LoadMeasurementUnitsPaginated(page: event.page - 1, pageSize: event.pageSize));
        } else {
          emit(MeasurementUnitPaginatedLoaded(
            measurementUnits: paginatedResult.items,
            currentPage: paginatedResult.page,
            totalPages: paginatedResult.totalPages,
            totalItems: paginatedResult.totalCount,
            pageSize: event.pageSize,
          ));
        }
      },
    );
  }

  Future<void> _onCreateMeasurementUnit(
    CreateMeasurementUnit event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.create(event.measurementUnit);
    result.fold(
      (failure) {
        emit(MeasurementUnitError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is MeasurementUnitLoaded) {
          add(LoadMeasurementUnits());
        }
      },
      (_) {
        emit(const MeasurementUnitOperationSuccess('Measurement unit created successfully'));
        // Reload based on previous state
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadMeasurementUnits());
        }
      },
    );
  }

  Future<void> _onUpdateMeasurementUnit(
    UpdateMeasurementUnit event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.update(event.measurementUnit);
    result.fold(
      (failure) {
        emit(MeasurementUnitError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is MeasurementUnitLoaded) {
          add(LoadMeasurementUnits());
        }
      },
      (_) {
        emit(const MeasurementUnitOperationSuccess('Measurement unit updated successfully'));
        // Reload based on previous state
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadMeasurementUnits());
        }
      },
    );
  }

  Future<void> _onDeleteMeasurementUnit(
    DeleteMeasurementUnit event,
    Emitter<MeasurementUnitState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.delete(event.id);
    result.fold(
      (failure) {
        emit(MeasurementUnitError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is MeasurementUnitLoaded) {
          add(LoadMeasurementUnits());
        }
      },
      (_) {
        emit(const MeasurementUnitOperationSuccess('Measurement unit deleted successfully'));
        // Reload based on previous state
        if (previousState is MeasurementUnitPaginatedLoaded) {
          add(LoadMeasurementUnitsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadMeasurementUnits());
        }
      },
    );
  }
}
