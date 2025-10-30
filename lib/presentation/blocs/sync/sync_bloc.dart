import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/repositories/measurement_unit_repository.dart';
import '../../../domain/repositories/output_type_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/output_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final MeasurementUnitRepository measurementUnitRepository;
  final OutputTypeRepository outputTypeRepository;
  final ProductRepository productRepository;
  final OutputRepository outputRepository;
  final NetworkInfo networkInfo;
  Timer? _syncTimer;

  SyncBloc({
    required this.measurementUnitRepository,
    required this.outputTypeRepository,
    required this.productRepository,
    required this.outputRepository,
    required this.networkInfo,
  }) : super(SyncInitial()) {
    on<StartSync>(_onStartSync);
    on<AutoSync>(_onAutoSync);

    // Listen to connectivity changes
    networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        add(AutoSync());
      }
    });
  }

  Future<void> _onStartSync(
    StartSync event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncInProgress());
    await _performSync(emit);
  }

  Future<void> _onAutoSync(
    AutoSync event,
    Emitter<SyncState> emit,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    await _performSync(emit);
  }

  Future<void> _performSync(Emitter<SyncState> emit) async {
    try {
      // Sync all entities
      final results = await Future.wait([
        measurementUnitRepository.sync(),
        outputTypeRepository.sync(),
        productRepository.sync(),
        outputRepository.sync(),
      ]);

      // Check if any sync failed
      final failures = results.where((result) => result.isLeft()).toList();

      if (failures.isEmpty) {
        emit(const SyncSuccess('All data synchronized successfully'));
      } else {
        emit(const SyncFailure('Some data failed to synchronize'));
      }
    } catch (e) {
      emit(SyncFailure('Sync failed: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }
}
