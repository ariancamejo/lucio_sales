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
      (paginatedResult) => emit(OutputTypePaginatedLoaded(
        outputTypes: paginatedResult.items,
        currentPage: paginatedResult.page,
        totalPages: paginatedResult.totalPages,
        totalItems: paginatedResult.totalCount,
      )),
    );
  }

  Future<void> _onCreateOutputType(
    CreateOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    final result = await repository.create(event.outputType);
    result.fold(
      (failure) => emit(OutputTypeError(failure.message)),
      (_) {
        emit(const OutputTypeOperationSuccess('Output type created successfully'));
        add(LoadOutputTypes());
      },
    );
  }

  Future<void> _onUpdateOutputType(
    UpdateOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    final result = await repository.update(event.outputType);
    result.fold(
      (failure) => emit(OutputTypeError(failure.message)),
      (_) {
        emit(const OutputTypeOperationSuccess('Output type updated successfully'));
        add(LoadOutputTypes());
      },
    );
  }

  Future<void> _onDeleteOutputType(
    DeleteOutputType event,
    Emitter<OutputTypeState> emit,
  ) async {
    final result = await repository.delete(event.id);
    result.fold(
      (failure) => emit(OutputTypeError(failure.message)),
      (_) {
        emit(const OutputTypeOperationSuccess('Output type deleted successfully'));
        add(LoadOutputTypes());
      },
    );
  }
}
