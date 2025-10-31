import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/output_type_repository.dart';
import 'output_type_event.dart';
import 'output_type_state.dart';

class OutputTypeBloc extends Bloc<OutputTypeEvent, OutputTypeState> {
  final OutputTypeRepository repository;

  OutputTypeBloc({required this.repository}) : super(OutputTypeInitial()) {
    on<LoadOutputTypes>(_onLoadOutputTypes);
    on<LoadOutputTypesPaginated>(_onLoadOutputTypesPaginated);
    on<CreateOutputType>(_onCreateOutputType);
    on<UpdateOutputType>(_onUpdateOutputType);
    on<DeleteOutputType>(_onDeleteOutputType);
  }

  Future<void> _onLoadOutputTypes(
    LoadOutputTypes event,
    Emitter<OutputTypeState> emit,
  ) async {
    emit(OutputTypeLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(OutputTypeError(failure.message)),
      (outputTypes) => emit(OutputTypeLoaded(outputTypes)),
    );
  }

  Future<void> _onLoadOutputTypesPaginated(
    LoadOutputTypesPaginated event,
    Emitter<OutputTypeState> emit,
  ) async {
    emit(OutputTypeLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
    );
    result.fold(
      (failure) => emit(OutputTypeError(failure.message)),
      (paginatedResult) {
        // If current page is empty and not the first page, go to previous page
        if (paginatedResult.items.isEmpty && event.page > 1) {
          add(LoadOutputTypesPaginated(page: event.page - 1, pageSize: event.pageSize));
        } else {
          emit(OutputTypePaginatedLoaded(
            outputTypes: paginatedResult.items,
            currentPage: paginatedResult.page,
            totalPages: paginatedResult.totalPages,
            totalItems: paginatedResult.totalCount,
            pageSize: event.pageSize,
          ));
        }
      },
    );
  }

  Future<void> _onCreateOutputType(
    CreateOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.create(event.outputType);
    result.fold(
      (failure) {
        emit(OutputTypeError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputTypeLoaded) {
          add(LoadOutputTypes());
        }
      },
      (_) {
        emit(const OutputTypeOperationSuccess('Output type created successfully'));
        // Reload based on previous state
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputTypes());
        }
      },
    );
  }

  Future<void> _onUpdateOutputType(
    UpdateOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.update(event.outputType);
    result.fold(
      (failure) {
        emit(OutputTypeError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputTypeLoaded) {
          add(LoadOutputTypes());
        }
      },
      (_) {
        emit(const OutputTypeOperationSuccess('Output type updated successfully'));
        // Reload based on previous state
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputTypes());
        }
      },
    );
  }

  Future<void> _onDeleteOutputType(
    DeleteOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.delete(event.id);
    result.fold(
      (failure) {
        emit(OutputTypeError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputTypeLoaded) {
          add(LoadOutputTypes());
        }
      },
      (_) {
        emit(const OutputTypeOperationSuccess('Output type deleted successfully'));
        // Reload based on previous state
        if (previousState is OutputTypePaginatedLoaded) {
          add(LoadOutputTypesPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputTypes());
        }
      },
    );
  }
}
