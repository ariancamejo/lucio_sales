import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/product/product_event.dart';
import '../blocs/product/product_state.dart';

class SearchableProductField extends StatefulWidget {
  final Product? initialProduct;
  final ValueChanged<Product?> onChanged;
  final String? Function(Product?)? validator;
  final bool enabled;
  final String labelText;

  const SearchableProductField({
    super.key,
    this.initialProduct,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelText = 'Product',
  });

  @override
  State<SearchableProductField> createState() => _SearchableProductFieldState();
}

class _SearchableProductFieldState extends State<SearchableProductField> {
  final TextEditingController _textController = TextEditingController();
  Product? _selectedProduct;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct;
    if (_selectedProduct != null) {
      _textController.text = '${_selectedProduct!.name} (${_selectedProduct!.code})';
    }
    // Load all products with includeInactive
    context.read<ProductBloc>().add(const LoadProducts(includeInactive: true));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _validateSelection() {
    if (widget.validator != null) {
      final error = widget.validator!(_selectedProduct);
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        List<Product> allProducts = [];
        if (state is ProductLoaded) {
          allProducts = state.products;
        } else if (state is ProductPaginatedLoaded) {
          allProducts = state.products;
        }

        // Filter only active products for selection
        final activeProducts = allProducts.where((p) => p.active).toList();

        if (state is ProductLoading && activeProducts.isEmpty) {
          return const LinearProgressIndicator();
        }

        return FormField<Product>(
          initialValue: _selectedProduct,
          validator: widget.validator,
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<Product>(
                  initialValue: _selectedProduct != null
                      ? TextEditingValue(
                          text: '${_selectedProduct!.name} (${_selectedProduct!.code})')
                      : null,
                  displayStringForOption: (Product product) =>
                      '${product.name} (${product.code})',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return activeProducts;
                    }
                    final searchText = textEditingValue.text.toLowerCase();
                    return activeProducts.where((Product product) {
                      final name = product.name.toLowerCase();
                      final code = product.code.toLowerCase();
                      return name.contains(searchText) || code.contains(searchText);
                    });
                  },
                  onSelected: (Product product) {
                    setState(() {
                      _selectedProduct = product;
                      _textController.text = '${product.name} (${product.code})';
                    });
                    widget.onChanged(product);
                    formFieldState.didChange(product);
                    _validateSelection();
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      enabled: widget.enabled,
                      decoration: InputDecoration(
                        labelText: widget.labelText,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.inventory_2),
                        suffixIcon: _selectedProduct != null && widget.enabled
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedProduct = null;
                                    textEditingController.clear();
                                  });
                                  widget.onChanged(null);
                                  formFieldState.didChange(null);
                                  _validateSelection();
                                },
                              )
                            : const Icon(Icons.arrow_drop_down),
                        errorText: formFieldState.errorText,
                        helperText: 'Type to search by name or code',
                      ),
                      onChanged: (value) {
                        // If user modifies text, clear selection
                        if (_selectedProduct != null &&
                            value != '${_selectedProduct!.name} (${_selectedProduct!.code})') {
                          setState(() {
                            _selectedProduct = null;
                          });
                          widget.onChanged(null);
                          formFieldState.didChange(null);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<Product> onSelected,
                    Iterable<Product> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 250,
                            maxWidth: 400,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Product product = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(product);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.green,
                                        child: Text(
                                          product.code,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Code: ${product.code} • Stock: ${product.quantity.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
