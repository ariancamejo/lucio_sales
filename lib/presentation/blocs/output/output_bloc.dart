import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/output_repository.dart';
import 'output_event.dart';
import 'output_state.dart';

class OutputBloc extends Bloc<OutputEvent, OutputState> {
  final OutputRepository repository;

  OutputBloc({required this.repository}) : super(OutputInitial()) {
    on<LoadOutputs>(_onLoadOutputs);
    on<LoadOutputsPaginated>(_onLoadOutputsPaginated);
    on<LoadOutputsByDateRange>(_onLoadOutputsByDateRange);
    on<LoadOutputsByType>(_onLoadOutputsByType);
    on<SearchAndFilterOutputs>(_onSearchAndFilterOutputs);
    on<CreateOutput>(_onCreateOutput);
    on<UpdateOutput>(_onUpdateOutput);
    on<DeleteOutput>(_onDeleteOutput);
    on<LoadSalesByDay>(_onLoadSalesByDay);
    on<LoadSalesByMonth>(_onLoadSalesByMonth);
    on<LoadSalesByYear>(_onLoadSalesByYear);
    on<LoadIPVReport>(_onLoadIPVReport);
  }

  Future<void> _onLoadOutputs(
    LoadOutputs event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onLoadOutputsPaginated(
    LoadOutputsPaginated event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
    );
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (paginatedResult) => emit(OutputPaginatedLoaded(
        outputs: paginatedResult.items,
        currentPage: paginatedResult.page,
        totalPages: paginatedResult.totalPages,
        totalItems: paginatedResult.totalCount,
      )),
    );
  }

  Future<void> _onLoadOutputsByDateRange(
    LoadOutputsByDateRange event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getByDateRange(event.startDate, event.endDate);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onLoadOutputsByType(
    LoadOutputsByType event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getByType(event.outputTypeId);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onSearchAndFilterOutputs(
    SearchAndFilterOutputs event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) {
        var filteredOutputs = outputs;

        // Apply search query (by product name)
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          final query = event.searchQuery!.toLowerCase();
          filteredOutputs = filteredOutputs.where((output) {
            final productName = output.product?.name.toLowerCase() ?? '';
            return productName.contains(query);
          }).toList();
        }

        // Apply date range filter
        if (event.startDate != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.date.isAfter(event.startDate!) ||
                                 output.date.isAtSameMomentAs(event.startDate!))
              .toList();
        }
        if (event.endDate != null) {
          // Set end date to end of day
          final endOfDay = DateTime(
            event.endDate!.year,
            event.endDate!.month,
            event.endDate!.day,
            23,
            59,
            59,
          );
          filteredOutputs = filteredOutputs
              .where((output) => output.date.isBefore(endOfDay) ||
                                 output.date.isAtSameMomentAs(endOfDay))
              .toList();
        }

        // Apply output type filter
        if (event.outputTypeId != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.outputTypeId == event.outputTypeId)
              .toList();
        }

        // Apply quantity range filter
        if (event.minQuantity != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.quantity >= event.minQuantity!)
              .toList();
        }
        if (event.maxQuantity != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.quantity <= event.maxQuantity!)
              .toList();
        }

        // Apply amount range filter
        if (event.minAmount != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.totalAmount >= event.minAmount!)
              .toList();
        }
        if (event.maxAmount != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.totalAmount <= event.maxAmount!)
              .toList();
        }

        emit(OutputLoaded(filteredOutputs));
      },
    );
  }

  Future<void> _onCreateOutput(
    CreateOutput event,
    Emitter<OutputState> emit,
  ) async {
    final result = await repository.create(event.output);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (_) {
        emit(const OutputOperationSuccess('Output created successfully'));
        // Let the UI handle reload with pagination
      },
    );
  }

  Future<void> _onUpdateOutput(
    UpdateOutput event,
    Emitter<OutputState> emit,
  ) async {
    final result = await repository.update(event.output);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (_) {
        emit(const OutputOperationSuccess('Output updated successfully'));
        // Let the UI handle reload with pagination
      },
    );
  }

  Future<void> _onDeleteOutput(
    DeleteOutput event,
    Emitter<OutputState> emit,
  ) async {
    final result = await repository.delete(event.id);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (_) {
        emit(const OutputOperationSuccess('Output deleted successfully'));
        // Let the UI handle reload with pagination
      },
    );
  }

  Future<void> _onLoadSalesByDay(
    LoadSalesByDay event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByDay(event.date);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadSalesByMonth(
    LoadSalesByMonth event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByMonth(event.year, event.month);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadSalesByYear(
    LoadSalesByYear event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByYear(event.year);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadIPVReport(
    LoadIPVReport event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getIPVReport();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(IPVReportLoaded(report)),
    );
  }
}
