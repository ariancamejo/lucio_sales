import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object> get props => [];
}

class SyncInitial extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncSuccess extends SyncState {
  final String message;

  const SyncSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SyncFailure extends SyncState {
  final String message;

  const SyncFailure(this.message);

  @override
  List<Object> get props => [message];
}
