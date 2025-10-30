import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';

import 'product_form_screen.dart';
import 'product_search_delegate.dart';
import '../product_entry/product_entry_form_screen.dart';
import '../home/home_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  bool? _activeFilter;
  double? _minPrice;
  double? _maxPrice;
  double? _minQuantity;
  double? _maxQuantity;
  double? _minCost;
  double? _maxCost;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  void _loadPage(int page) {
    context.read<ProductBloc>().add(
      LoadProductsPaginated(
        page: page,
        pageSize: _pageSize,
        includeInactive: _activeFilter == null,
      ),
    );
  }

  Future<void> _applyFilters() async {
    if (_activeFilter == null &&
        _minPrice == null &&
        _maxPrice == null &&
        _minQuantity == null &&
        _maxQuantity == null &&
        _minCost == null &&
        _maxCost == null) {
      _loadPage(_currentPage);
    } else {
      context.read<ProductBloc>().add(
            SearchAndFilterProducts(
              activeFilter: _activeFilter,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              minQuantity: _minQuantity,
              maxQuantity: _maxQuantity,
              minCost: _minCost,
              maxCost: _maxCost,
            ),
          );
    }
    // Wait a bit for the bloc to process the event
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void _showFilterDialog() {
    final minPriceController = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxPriceController = TextEditingController(text: _maxPrice?.toString() ?? '');
    final minQuantityController = TextEditingController(text: _minQuantity?.toString() ?? '');
    final maxQuantityController = TextEditingController(text: _maxQuantity?.toString() ?? '');
    final minCostController = TextEditingController(text: _minCost?.toString() ?? '');
    final maxCostController = TextEditingController(text: _maxCost?.toString() ?? '');

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
                          _activeFilter = null;
                          minPriceController.clear();
                          maxPriceController.clear();
                          minQuantityController.clear();
                          maxQuantityController.clear();
                          minCostController.clear();
                          maxCostController.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Active')),
                    ButtonSegment(value: false, label: Text('Inactive')),
                  ],
                  selected: {_activeFilter},
                  onSelectionChanged: (Set<bool?> newSelection) {
                    setDialogState(() {
                      _activeFilter = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Min Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Max Price',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                const SizedBox(height: 16),
                Text('Cost Range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCostController,
                        decoration: const InputDecoration(
                          labelText: 'Min Cost',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxCostController,
                        decoration: const InputDecoration(
                          labelText: 'Max Cost',
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
                      _minPrice = double.tryParse(minPriceController.text);
                      _maxPrice = double.tryParse(maxPriceController.text);
                      _minQuantity = double.tryParse(minQuantityController.text);
                      _maxQuantity = double.tryParse(maxQuantityController.text);
                      _minCost = double.tryParse(minCostController.text);
                      _maxCost = double.tryParse(maxCostController.text);
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
    return _activeFilter != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _minQuantity != null ||
        _maxQuantity != null ||
        _minCost != null ||
        _maxCost != null;
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
                delegate: ProductSearchDelegate(
                  activeFilter: _activeFilter,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  minQuantity: _minQuantity,
                  maxQuantity: _maxQuantity,
                  minCost: _minCost,
                  maxCost: _maxCost,
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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              );
              // Reload after adding product
              if (mounted) {
                _applyFilters();
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            _loadPage(_currentPage);
          } else if (state is ProductOperationSuccess) {
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
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductLoaded || state is ProductPaginatedLoaded) {
            final products = state is ProductLoaded
                ? state.products
                : (state as ProductPaginatedLoaded).products;
            final currentPage = state is ProductPaginatedLoaded ? state.currentPage : 1;
            final totalPages = state is ProductPaginatedLoaded ? state.totalPages : 1;
            final totalItems = state is ProductPaginatedLoaded ? state.totalItems : products.length;

            if (products.isEmpty) {
              return const Center(
                child: Text('No products found.\nTap + to add one or adjust filters.'),
              );
            }

            return RefreshIndicator(
              onRefresh: _applyFilters,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(product.id),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe left to delete
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: Text('Are you sure you want to delete "${product.name}"?'),
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
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductFormScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                                // Reload after edit
                                if (mounted) {
                                  _applyFilters();
                                }
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                context.read<ProductBloc>().add(DeleteProduct(product.id));
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
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProductFormScreen(
                                        product: product,
                                      ),
                                    ),
                                  );
                                  // Reload after edit
                                  if (mounted) {
                                    _applyFilters();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: product.active ? Colors.green : Colors.grey,
                                            child: Text(
                                              product.code,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!product.active)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.block,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: product.active ? null : Colors.grey,
                                                          decoration: product.active ? null : TextDecoration.lineThrough,
                                                        ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!product.active)
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 8),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.red, width: 1),
                                                    ),
                                                    child: const Text(
                                                      'INACTIVE',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${product.quantity}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                                                Text(
                                                  product.price.toStringAsFixed(2),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                        tooltip: 'More options',
                                        onSelected: (value) async {
                                          if (value == 'add_stock') {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => ProductEntryFormScreen(
                                                  preselectedProduct: product,
                                                ),
                                              ),
                                            );
                                            // Reload the list after adding stock
                                            if (mounted) {
                                              _applyFilters();
                                            }
                                          } else if (value == 'view_entries') {
                                            // Navegar a ProductEntry usando el HomeScreen
                                            homeScreenKey.currentState?.navigateToProductEntryWithFilter(
                                              product.id,
                                              product.name,
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'add_stock',
                                            child: Row(
                                              children: [
                                                Icon(Icons.add_circle_outline, size: 20),
                                                SizedBox(width: 12),
                                                Text('Add Stock'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'view_entries',
                                            child: Row(
                                              children: [
                                                Icon(Icons.history, size: 20),
                                                SizedBox(width: 12),
                                                Text('View Stock History'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
                  if (state is ProductPaginatedLoaded && totalPages > 1)
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
