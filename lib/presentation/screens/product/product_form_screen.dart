import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';
import '../../blocs/measurement_unit/measurement_unit_state.dart';

class ProductFormScreen extends StatefulWidget {
  /// Product ID for editing (from route parameter)
  final String? productId;

  /// Legacy support for passing Product object directly
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.productId,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedMeasurementUnitId;
  bool _active = false;
  Product? _loadedProduct;
  bool _isLoadingData = false;
  String? _codeError;
  Product? _duplicateProduct;

  bool get isEditing => widget.product != null || widget.productId != null;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    // If editing by ID, set loading state
    if (widget.productId != null && widget.product == null) {
      setState(() => _isLoadingData = true);
    }

    // Load measurement units
    context.read<MeasurementUnitBloc>().add(LoadMeasurementUnits());

    // If we have a product object, load it immediately
    if (widget.product != null) {
      _loadProductData(widget.product!);
    } else if (widget.productId != null) {
      // If we only have a productId, we need to load products first
      context.read<ProductBloc>().add(const LoadProducts());
    }
  }

  void _loadProductData(Product product) {
    _nameController.text = product.name;
    _codeController.text = product.code;
    _quantityController.text = product.quantity.toString();
    _costController.text = product.cost.toString();
    _priceController.text = product.price.toString();
    _selectedMeasurementUnitId = product.measurementUnitId;
    _active = product.active;
    _loadedProduct = product;
  }

  Future<void> _validateCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _codeError = null;
        _duplicateProduct = null;
      });
      return;
    }

    // Check if code exists
    final result = await sl<ProductBloc>().repository.getByCode(code.trim());

    result.fold(
      (failure) {
        // Error checking - assume code is available
        setState(() {
          _codeError = null;
          _duplicateProduct = null;
        });
      },
      (product) {
        // If editing and it's the same product, code is valid
        if (isEditing && _loadedProduct != null && product?.id == _loadedProduct!.id) {
          setState(() {
            _codeError = null;
            _duplicateProduct = null;
          });
        } else if (product != null) {
          // Code is already used by another product
          setState(() {
            _codeError = 'Code already exists for: ${product.name}';
            _duplicateProduct = product;
          });
        } else {
          // Code is available
          setState(() {
            _codeError = null;
            _duplicateProduct = null;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        // When products are loaded and we have a productId, find and load it
        if (state is ProductLoaded && widget.productId != null && _loadedProduct == null) {
          try {
            final product = state.products.firstWhere(
              (p) => p.id == widget.productId,
            );
            setState(() {
              _loadProductData(product);
              _isLoadingData = false; // Mark loading as complete
            });
          } catch (e) {
            debugPrint('Product with ID ${widget.productId} not found: $e');
            setState(() => _isLoadingData = false);
          }
        }
      },
      child: _isLoadingData
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Product' : 'New Product'),
        ),
        body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code *',
                border: const OutlineInputBorder(),
                hintText: 'e.g., P001',
                errorText: _codeError,
                suffixIcon: _codeError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : _codeController.text.isNotEmpty && _codeError == null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
              ),
              onChanged: (value) {
                _validateCode(value);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a code';
                }
                if (_codeError != null) {
                  return _codeError;
                }
                return null;
              },
            ),
            if (_duplicateProduct != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Product: ${_duplicateProduct!.name}\nPrice: \$${_duplicateProduct!.price}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quantity';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<MeasurementUnitBloc, MeasurementUnitState>(
              builder: (context, state) {
                if (state is MeasurementUnitLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedMeasurementUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Measurement Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: state.measurementUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit.id,
                        child: Text('${unit.name} (${unit.acronym})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMeasurementUnitId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a measurement unit';
                      }
                      return null;
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _active,
              onChanged: (value) {
                setState(() {
                  _active = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final authService = sl<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null && !isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Get the existing product (either from widget or loaded)
      final existingProduct = widget.product ?? _loadedProduct;

      final now = DateTime.now();
      final product = Product(
        id: isEditing ? existingProduct!.id : const Uuid().v4(),
        userId: isEditing ? existingProduct!.userId : currentUser!.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        quantity: double.parse(_quantityController.text),
        measurementUnitId: _selectedMeasurementUnitId!,
        cost: double.parse(_costController.text),
        price: double.parse(_priceController.text),
        active: _active,
        createdAt: isEditing ? existingProduct!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        context.read<ProductBloc>().add(UpdateProduct(product));
      } else {
        context.read<ProductBloc>().add(CreateProduct(product));
      }

      Navigator.of(context).pop();
    }
  }
}
