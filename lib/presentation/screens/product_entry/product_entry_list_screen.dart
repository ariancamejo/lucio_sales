import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/product_entry/product_entry_bloc.dart';
import '../../blocs/product_entry/product_entry_event.dart';
import '../../blocs/product_entry/product_entry_state.dart';

import 'product_entry_form_screen.dart';
import 'product_entry_search_delegate.dart';

class ProductEntryListScreen extends StatefulWidget {
  const ProductEntryListScreen({super.key});

  @override
  State<ProductEntryListScreen> createState() => _ProductEntryListScreenState();
}

// Global key para acceder al estado desde fuera
final GlobalKey<_ProductEntryListScreenState> productEntryListKey = GlobalKey<_ProductEntryListScreenState>();

class _ProductEntryListScreenState extends State<ProductEntryListScreen> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  String? _productIdFilter;
  String? _productName;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minQuantity;
  double? _maxQuantity;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  // Método público para aplicar filtro de producto desde fuera
  void applyProductFilter(String productId, String productName) {
    setState(() {
      _productIdFilter = productId;
      _productName = productName;
      _currentPage = 1;
    });
    _applyFilters();
  }

  // Método público para limpiar filtros
  void clearFilters() {
    setState(() {
      _productIdFilter = null;
      _productName = null;
      _startDate = null;
      _endDate = null;
      _minQuantity = null;
      _maxQuantity = null;
      _currentPage = 1;
    });
    _loadPage(1);
  }

  void _loadPage(int page) {
    context.read<ProductEntryBloc>().add(
      LoadProductEntriesPaginated(page: page, pageSize: _pageSize),
    );
  }

  void _applyFilters() {
    if (_productIdFilter == null &&
        _startDate == null &&
        _endDate == null &&
        _minQuantity == null &&
        _maxQuantity == null) {
      _loadPage(_currentPage);
    } else {
      context.read<ProductEntryBloc>().add(
            SearchAndFilterProductEntries(
              productIdFilter: _productIdFilter,
              startDate: _startDate,
              endDate: _endDate,
              minQuantity: _minQuantity,
              maxQuantity: _maxQuantity,
            ),
          );
    }
  }

  void _showFilterDialog() {
    final minQuantityController = TextEditingController(text: _minQuantity?.toString() ?? '');
    final maxQuantityController = TextEditingController(text: _maxQuantity?.toString() ?? '');

    // Load products for the filter
    context.read<ProductBloc>().add(const LoadProducts(includeInactive: true));

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
                          _productIdFilter = null;
                          _productName = null;
                          minQuantityController.clear();
                          maxQuantityController.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Product', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    List<Product> allProducts = [];
                    if (state is ProductLoaded) {
                      allProducts = state.products;
                    } else if (state is ProductPaginatedLoaded) {
                      allProducts = state.products;
                    }

                    final activeProducts = allProducts.where((p) => p.active).toList();

                    // Verificar si el productIdFilter actual existe en activeProducts
                    String? currentValue = _productIdFilter;
                    if (currentValue != null) {
                      final exists = activeProducts.any((p) => p.id == currentValue);
                      if (!exists) {
                        // Si el producto filtrado ya no está activo o no existe, limpiar el filtro
                        currentValue = null;
                      }
                    }

                    return DropdownButtonFormField<String>(
                      value: currentValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'All Products',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Products'),
                        ),
                        ...activeProducts.map((product) {
                          return DropdownMenuItem<String>(
                            value: product.id,
                            child: Text(
                              '${product.name} (${product.code})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _productIdFilter = value;
                          if (value != null) {
                            final selectedProduct = activeProducts.firstWhere((p) => p.id == value);
                            _productName = selectedProduct.name;
                          } else {
                            _productName = null;
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minQuantity = double.tryParse(minQuantityController.text);
                      _maxQuantity = double.tryParse(maxQuantityController.text);
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
    return _productIdFilter != null ||
        _startDate != null ||
        _endDate != null ||
        _minQuantity != null ||
        _maxQuantity != null;
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
                delegate: ProductEntrySearchDelegate(
                  currentPage: _currentPage,
                  pageSize: _pageSize,
                  productIdFilter: _productIdFilter,
                  startDate: _startDate,
                  endDate: _endDate,
                  minQuantity: _minQuantity,
                  maxQuantity: _maxQuantity,
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
                  builder: (context) => const ProductEntryFormScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocConsumer<ProductEntryBloc, ProductEntryState>(
        listener: (context, state) {
          if (state is ProductEntryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            _loadPage(_currentPage);
          } else if (state is ProductEntryOperationSuccess) {
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
          if (state is ProductEntryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductEntryLoaded || state is ProductEntryPaginatedLoaded) {
            final productEntries = state is ProductEntryLoaded
                ? state.productEntries
                : (state as ProductEntryPaginatedLoaded).productEntries;
            final currentPage = state is ProductEntryPaginatedLoaded ? state.currentPage : 1;
            final totalPages = state is ProductEntryPaginatedLoaded ? state.totalPages : 1;
            final totalItems = state is ProductEntryPaginatedLoaded ? state.totalItems : productEntries.length;

            if (productEntries.isEmpty) {
              return const Center(
                child: Text('No product entries found.\nTap + to add one.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _applyFilters();
              },
              child: Column(
                children: [
                  if (_productIdFilter != null && _productName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtering by: $_productName',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _productIdFilter = null;
                                _productName = null;
                              });
                              _applyFilters();
                            },
                            tooltip: 'Clear filter',
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                      itemCount: productEntries.length,
                      itemBuilder: (context, index) {
                        final entry = productEntries[index];
                        final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(entry.id),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe left to delete
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text('Are you sure you want to delete this entry? This will reduce the product quantity.'),
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
                                    builder: (context) => ProductEntryFormScreen(
                                      productEntry: entry,
                                    ),
                                  ),
                                );
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                context.read<ProductEntryBloc>().add(DeleteProductEntry(entry.id, entry));
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
                                      builder: (context) => ProductEntryFormScreen(
                                        productEntry: entry,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          entry.quantity.toStringAsFixed(0),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.product?.name ?? 'Unknown Product',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.add_circle_outline, size: 14, color: Colors.grey[600]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${entry.quantity}',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: Colors.grey[600],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  dateFormat.format(entry.date),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[500],
                                                      ),
                                                ),
                                              ],
                                            ),
                                            if (entry.notes != null && entry.notes!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  entry.notes!,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
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
                  if (state is ProductEntryPaginatedLoaded && totalPages > 1)
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
