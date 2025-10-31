import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/debouncer.dart';
import '../../../domain/entities/output.dart';
import '../../blocs/output/output_bloc.dart';
import '../../blocs/output/output_event.dart';
import '../../blocs/output/output_state.dart';

class OutputSearchDelegate extends SearchDelegate<Output?> {
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  final DateTime? startDate;
  final DateTime? endDate;
  final String? outputTypeId;
  final double? minQuantity;
  final double? maxQuantity;
  final double? minAmount;
  final double? maxAmount;

  OutputSearchDelegate({
    this.startDate,
    this.endDate,
    this.outputTypeId,
    this.minQuantity,
    this.maxQuantity,
    this.minAmount,
    this.maxAmount,
  });

  @override
  String get searchFieldLabel => 'Search by product name...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a product name'),
      );
    }

    context.read<OutputBloc>().add(
          SearchAndFilterOutputs(
            searchQuery: query,
            startDate: startDate,
            endDate: endDate,
            outputTypeId: outputTypeId,
            minQuantity: minQuantity,
            maxQuantity: maxQuantity,
            minAmount: minAmount,
            maxAmount: maxAmount,
          ),
        );

    return BlocBuilder<OutputBloc, OutputState>(
      builder: (context, state) {
        if (state is OutputLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OutputLoaded) {
          final outputs = state.outputs;

          if (outputs.isEmpty) {
            return const Center(
              child: Text('No outputs found'),
            );
          }

          return ListView.builder(
            itemCount: outputs.length,
            itemBuilder: (context, index) {
              final output = outputs[index];
              final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

              return ListTile(
                title: Text(output.product?.name ?? 'Unknown Product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity: ${output.quantity} ${output.measurementUnit?.acronym ?? ''}',
                    ),
                    Text(
                      'Type: ${output.outputType?.name ?? 'Unknown'}',
                    ),
                    Text(
                      'Amount: \$${output.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Date: ${dateFormat.format(output.date)}',
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    context.push('/outputs/${output.id}/edit');
                  },
                ),
                onTap: () => close(context, output),
              );
            },
          );
        }

        return const Center(
          child: Text('Something went wrong'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a product name to search'),
      );
    }

    // Use debouncer to delay search while user is typing
    _debouncer.run(() {
      context.read<OutputBloc>().add(
            SearchAndFilterOutputs(
              searchQuery: query,
              startDate: startDate,
              endDate: endDate,
              outputTypeId: outputTypeId,
              minQuantity: minQuantity,
              maxQuantity: maxQuantity,
              minAmount: minAmount,
              maxAmount: maxAmount,
            ),
          );
    });

    return BlocBuilder<OutputBloc, OutputState>(
      builder: (context, state) {
        if (state is OutputLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OutputLoaded) {
          final outputs = state.outputs;

          if (outputs.isEmpty) {
            return const Center(
              child: Text('No outputs found'),
            );
          }

          return ListView.builder(
            itemCount: outputs.length,
            itemBuilder: (context, index) {
              final output = outputs[index];
              final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

              return ListTile(
                title: Text(output.product?.name ?? 'Unknown Product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity: ${output.quantity} ${output.measurementUnit?.acronym ?? ''}',
                    ),
                    Text(
                      'Type: ${output.outputType?.name ?? 'Unknown'}',
                    ),
                    Text(
                      'Amount: \$${output.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Date: ${dateFormat.format(output.date)}',
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    context.push('/outputs/${output.id}/edit');
                  },
                ),
                onTap: () => close(context, output),
              );
            },
          );
        }

        return const Center(
          child: Text('Something went wrong'),
        );
      },
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
