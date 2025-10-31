import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_entry.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/product_entry/product_entry_bloc.dart';
import '../../blocs/product_entry/product_entry_event.dart';
import '../../blocs/product_entry/product_entry_state.dart';
import '../../widgets/searchable_product_field.dart';

class ProductEntryFormScreen extends StatefulWidget {
  /// Entry ID for editing existing entry
  final String? entryId;

  /// Pre-selected product ID (from query parameters or navigation)
  final String? preSelectedProductId;

  const ProductEntryFormScreen({
    super.key,
    this.entryId,
    this.preSelectedProductId,
  });

  @override
  State<ProductEntryFormScreen> createState() => _ProductEntryFormScreenState();
}

class _ProductEntryFormScreenState extends State<ProductEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingData = false;
  ProductEntry? _loadedEntry;

  bool get isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    // Debug: Print received parameters
    debugPrint('ProductEntryFormScreen initialized');
    debugPrint('entryId: ${widget.entryId}');
    debugPrint('preSelectedProductId: ${widget.preSelectedProductId}');

    // If editing, set loading state
    if (widget.entryId != null) {
      setState(() => _isLoadingData = true);
    }

    // Load products first
    context.read<ProductBloc>().add(const LoadProducts());

    // If editing, load product entries
    if (widget.entryId != null) {
      context.read<ProductEntryBloc>().add(LoadProductEntries());
    }

    // Note: If preSelectedProductId is provided, the product will be auto-selected
    // when ProductBloc finishes loading (see BlocListener in build method)
  }

  void _loadEntryData(ProductEntry entry) {
    _quantityController.text = entry.quantity.toString();
    _notesController.text = entry.notes ?? '';
    _selectedProduct = entry.product;
    _selectedDate = entry.date;
    _loadedEntry = entry;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null && !isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final notes = _notesController.text.trim();

      if (!isEditing) {
        // Create new entry
        final newEntry = ProductEntry(
          id: '',
          userId: '',
          productId: _selectedProduct!.id,
          quantity: quantity,
          date: _selectedDate,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        context.read<ProductEntryBloc>().add(CreateProductEntry(newEntry));
      } else {
        // Update existing entry
        final updatedEntry = _loadedEntry!.copyWith(
          quantity: quantity,
          date: _selectedDate,
          notes: notes.isEmpty ? null : notes,
        );

        context.read<ProductEntryBloc>().add(
          UpdateProductEntry(updatedEntry, _loadedEntry!),
        );
      }
      // Don't pop here - let the BlocListener handle it after success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to ProductBloc to auto-select product when preSelectedProductId is provided
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            debugPrint('ProductBloc state changed: ${state.runtimeType}');

            // When products are loaded and we have a preSelectedProductId, find and select it
            if (state is ProductLoaded && widget.preSelectedProductId != null) {
              debugPrint('Products loaded! Count: ${state.products.length}');
              debugPrint('Looking for product ID: ${widget.preSelectedProductId}');
              debugPrint('Current selected product: ${_selectedProduct?.name}');

              // Only auto-select if no product is selected yet
              if (_selectedProduct == null) {
                try {
                  // Find the product with matching ID
                  final product = state.products.firstWhere(
                    (p) => p.id == widget.preSelectedProductId,
                  );
                  debugPrint('Found product: ${product.name}');
                  setState(() {
                    _selectedProduct = product;
                  });
                  debugPrint('Product auto-selected!');
                } catch (e) {
                  // Product not found, ignore
                  debugPrint('❌ Product with ID ${widget.preSelectedProductId} not found: $e');
                }
              }
            }
          },
        ),
        // Listen to ProductEntryBloc for loading entries (when editing)
        BlocListener<ProductEntryBloc, ProductEntryState>(
          listener: (context, state) {
            // Load entry data when entries are loaded
            if (state is ProductEntryLoaded && widget.entryId != null && _loadedEntry == null) {
              try {
                final entry = state.productEntries.firstWhere(
                  (e) => e.id == widget.entryId,
                );
                setState(() {
                  _loadEntryData(entry);
                  _isLoadingData = false; // Mark loading as complete
                });
              } catch (e) {
                debugPrint('ProductEntry with ID ${widget.entryId} not found: $e');
                setState(() => _isLoadingData = false);
              }
            }

            // Handle operation results
            if (state is ProductEntryOperationSuccess) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Close the form and return to the list
              Navigator.of(context).pop();
            } else if (state is ProductEntryError) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
              // Reset loading state
              setState(() => _isLoading = false);
            }
          },
        ),
      ],
      child: _isLoadingData
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Stock Entry' : 'New Stock Entry'),
        ),
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isEditing)
                  SearchableProductField(
                    initialProduct: _selectedProduct,
                    onChanged: (product) {
                      setState(() {
                        _selectedProduct = product;
                      });
                    },
                    validator: (product) {
                      if (product == null) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  _loadedEntry?.product?.name ?? 'Product ID: ${_loadedEntry?.productId ?? ""}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (_loadedEntry?.product != null)
                                  Text(
                                    'Code: ${_loadedEntry!.product!.code}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add_shopping_cart),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quantity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Quantity must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.today),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                      },
                      tooltip: 'Set to today',
                    ),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Validate form before submitting
                          if (_formKey.currentState?.validate() ?? false) {
                            _handleSubmit();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update Entry' : 'Add Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
