import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_entry.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product_entry/product_entry_bloc.dart';
import '../../blocs/product_entry/product_entry_event.dart';
import '../../blocs/product_entry/product_entry_state.dart';
import '../../widgets/searchable_product_field.dart';

class ProductEntryFormScreen extends StatefulWidget {
  final ProductEntry? productEntry;
  final Product? preselectedProduct;

  const ProductEntryFormScreen({
    super.key,
    this.productEntry,
    this.preselectedProduct,
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

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());

    if (widget.productEntry != null) {
      _quantityController.text = widget.productEntry!.quantity.toString();
      _notesController.text = widget.productEntry!.notes ?? '';
      _selectedDate = widget.productEntry!.date;
      _selectedProduct = widget.productEntry!.product;
    } else if (widget.preselectedProduct != null) {
      // If a product is preselected, set it
      _selectedProduct = widget.preselectedProduct;
    }
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
    if (_selectedProduct == null && widget.productEntry == null) {
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

      if (widget.productEntry == null) {
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
        final updatedEntry = widget.productEntry!.copyWith(
          quantity: quantity,
          date: _selectedDate,
          notes: notes.isEmpty ? null : notes,
        );

        context.read<ProductEntryBloc>().add(
          UpdateProductEntry(updatedEntry, widget.productEntry!),
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
    return BlocListener<ProductEntryBloc, ProductEntryState>(
      listener: (context, state) {
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.productEntry == null ? 'New Stock Entry' : 'Edit Stock Entry'),
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
                if (widget.productEntry == null)
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
                                  widget.productEntry!.product?.name ?? 'Product ID: ${widget.productEntry!.productId}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (widget.productEntry!.product != null)
                                  Text(
                                    'Code: ${widget.productEntry!.product!.code}',
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
                      : Text(widget.productEntry == null ? 'Add Entry' : 'Update Entry'),
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
