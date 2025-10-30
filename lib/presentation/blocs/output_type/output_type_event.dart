import 'package:equatable/equatable.dart';
import '../../../domain/entities/output_type.dart';

abstract class OutputTypeEvent extends Equatable {
  const OutputTypeEvent();

  @override
  List<Object> get props => [];
}

class LoadOutputTypes extends OutputTypeEvent {}

class LoadOutputTypesPaginated extends OutputTypeEvent {
  final int page;
  final int pageSize;

  const LoadOutputTypesPaginated({
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object> get props => [page, pageSize];
}

class CreateOutputType extends OutputTypeEvent {
  final OutputType outputType;

  const CreateOutputType(this.outputType);

  @override
  List<Object> get props => [outputType];
}

class UpdateOutputType extends OutputTypeEvent {
  final OutputType outputType;

  const UpdateOutputType(this.outputType);

  @override
  List<Object> get props => [outputType];
}

class DeleteOutputType extends OutputTypeEvent {
  final String id;

  const DeleteOutputType(this.id);

  @override
  List<Object> get props => [id];
}
