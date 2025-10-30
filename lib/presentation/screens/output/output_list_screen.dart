import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/output/output_bloc.dart';
import '../../blocs/output/output_event.dart';
import '../../blocs/output/output_state.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';
import '../../blocs/output_type/output_type_state.dart';

import 'output_form_screen.dart';
import 'output_search_delegate.dart';

class OutputListScreen extends StatefulWidget {
  const OutputListScreen({super.key});

  @override
  State<OutputListScreen> createState() => _OutputListScreenState();
}

class _OutputListScreenState extends State<OutputListScreen> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _outputTypeIdFilter;
  double? _minQuantity;
  double? _maxQuantity;
  double? _minAmount;
  double? _maxAmount;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
    // Load output types for filter dropdown
    context.read<OutputTypeBloc>().add(LoadOutputTypes());
  }

  void _loadPage(int page) {
    context.read<OutputBloc>().add(
      LoadOutputsPaginated(page: page, pageSize: _pageSize),
    );
  }

  void _applyFilters() {
    if (_startDate == null &&
        _endDate == null &&
        _outputTypeIdFilter == null &&
        _minQuantity == null &&
        _maxQuantity == null &&
        _minAmount == null &&
        _maxAmount == null) {
      _loadPage(_currentPage);
    } else {
      context.read<OutputBloc>().add(
            SearchAndFilterOutputs(
              startDate: _startDate,
              endDate: _endDate,
              outputTypeId: _outputTypeIdFilter,
              minQuantity: _minQuantity,
              maxQuantity: _maxQuantity,
              minAmount: _minAmount,
              maxAmount: _maxAmount,
            ),
          );
    }
  }

  void _showFilterDialog() {
    final minQuantityController = TextEditingController(text: _minQuantity?.toString() ?? '');
    final maxQuantityController = TextEditingController(text: _maxQuantity?.toString() ?? '');
    final minAmountController = TextEditingController(text: _minAmount?.toString() ?? '');
    final maxAmountController = TextEditingController(text: _maxAmount?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          _startDate = null;
                          _endDate = null;
                          _outputTypeIdFilter = null;
                          minQuantityController.clear();
                          maxQuantityController.clear();
                          minAmountController.clear();
                          maxAmountController.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() => _startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate != null
                            ? DateFormat('MMM dd, yyyy').format(_startDate!)
                            : 'Start Date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setDialogState(() => _endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'End Date'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Output Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BlocBuilder<OutputTypeBloc, OutputTypeState>(
                  builder: (context, state) {
                    if (state is OutputTypeLoaded || state is OutputTypePaginatedLoaded) {
                      final outputTypes = state is OutputTypeLoaded
                          ? state.outputTypes
                          : (state as OutputTypePaginatedLoaded).outputTypes;

                      return DropdownButtonFormField<String>(
                        value: _outputTypeIdFilter,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'All Types',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...outputTypes.map((type) => DropdownMenuItem<String>(
                                value: type.id,
                                child: Text(type.name),
                              )),
                        ],
                        onChanged: (value) {
                          setDialogState(() => _outputTypeIdFilter = value);
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),
                Text('Quantity Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Min Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxQuantityController,
                        decoration: const InputDecoration(
                          labelText: 'Max Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Amount Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Min Amount',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Max Amount',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minQuantity = double.tryParse(minQuantityController.text);
                      _maxQuantity = double.tryParse(maxQuantityController.text);
                      _minAmount = double.tryParse(minAmountController.text);
                      _maxAmount = double.tryParse(maxAmountController.text);
                    });
                    _applyFilters();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply Filters'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _startDate != null ||
        _endDate != null ||
        _outputTypeIdFilter != null ||
        _minQuantity != null ||
        _maxQuantity != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'search',
            mini: true,
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: OutputSearchDelegate(
                  startDate: _startDate,
                  endDate: _endDate,
                  outputTypeId: _outputTypeIdFilter,
                  minQuantity: _minQuantity,
                  maxQuantity: _maxQuantity,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                ),
              );
              // Restore filters after search closes
              _applyFilters();
            },
            child: const Icon(Icons.search),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'filter',
            mini: true,
            onPressed: _showFilterDialog,
            child: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OutputFormScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocConsumer<OutputBloc, OutputState>(
        listener: (context, state) {
          if (state is OutputError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            // Reload list to ensure UI reflects actual database state
            _loadPage(_currentPage);
          } else if (state is OutputOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _loadPage(_currentPage);
          }
        },
        builder: (context, state) {
          if (state is OutputLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OutputLoaded || state is OutputPaginatedLoaded) {
            final outputs = state is OutputLoaded
                ? state.outputs
                : (state as OutputPaginatedLoaded).outputs;
            final currentPage = state is OutputPaginatedLoaded ? state.currentPage : 1;
            final totalPages = state is OutputPaginatedLoaded ? state.totalPages : 1;
            final totalItems = state is OutputPaginatedLoaded ? state.totalItems : outputs.length;

            if (outputs.isEmpty) {
              return const Center(
                child: Text('No outputs found.\nTap + to add one.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _applyFilters();
              },
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                      itemCount: outputs.length,
                      itemBuilder: (context, index) {
                        final output = outputs[index];
                        final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(output.id),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe left to delete
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Output'),
                                    content: const Text('Are you sure you want to delete this output?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (direction == DismissDirection.startToEnd) {
                                // Swipe right to edit
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OutputFormScreen(
                                      output: output,
                                    ),
                                  ),
                                );
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                context.read<OutputBloc>().add(DeleteOutput(output.id));
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.white),
                                ],
                              ),
                            ),
                            child: Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => OutputFormScreen(
                                        output: output,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              output.product?.name ?? 'Unknown Product',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${output.quantity} ${output.measurementUnit?.acronym ?? ''}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.category_outlined, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    output.outputType?.name ?? 'Unknown',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.grey[600],
                                                        ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '\$${output.totalAmount.toStringAsFixed(2)}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  dateFormat.format(output.date),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[500],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (state is OutputPaginatedLoaded && totalPages > 1)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 72, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Page $currentPage of $totalPages ($totalItems items)',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadPage(_currentPage);
                                      }
                                    : null,
                              ),
                              Text('$currentPage'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < totalPages
                                    ? () {
                                        setState(() => _currentPage++);
                                        _loadPage(_currentPage);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

}
