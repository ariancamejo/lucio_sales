import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/output.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/output/output_bloc.dart';
import '../../blocs/output/output_event.dart';
import '../../blocs/output/output_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';
import '../../blocs/measurement_unit/measurement_unit_state.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';
import '../../blocs/output_type/output_type_state.dart';
import '../../widgets/searchable_product_field.dart';

class OutputFormScreen extends StatefulWidget {
  /// Output ID for editing (from route parameter)
  final String? outputId;

  const OutputFormScreen({
    super.key,
    this.outputId,
  });

  @override
  State<OutputFormScreen> createState() => _OutputFormScreenState();
}

class _OutputFormScreenState extends State<OutputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _totalAmountController = TextEditingController();

  Product? _selectedProduct;
  String? _selectedMeasurementUnitId;
  String? _selectedOutputTypeId;
  DateTime _selectedDate = DateTime.now();
  Output? _loadedOutput;

  bool _isLoadingData = false;

  bool get isEditing => widget.outputId != null;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);

    // Load all dependencies first
    context.read<ProductBloc>().add(const LoadProducts());
    context.read<MeasurementUnitBloc>().add(LoadMeasurementUnits());
    context.read<OutputTypeBloc>().add(LoadOutputTypes());

    // If editing, load the output entity
    if (widget.outputId != null) {
      context.read<OutputBloc>().add(LoadOutputs());
    } else {
      // For new outputs, we're done loading
      setState(() => _isLoadingData = false);
    }
  }

  void _loadOutputData(Output output) {
    _quantityController.text = output.quantity.toString();
    _totalAmountController.text = output.totalAmount.toString();
    _selectedProduct = output.product;
    _selectedMeasurementUnitId = output.measurementUnitId;
    _selectedOutputTypeId = output.outputTypeId;
    _selectedDate = output.date;
    _loadedOutput = output;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OutputBloc, OutputState>(
          listener: (context, state) {
            if (state is OutputLoaded && widget.outputId != null && _loadedOutput == null) {
              try {
                final output = state.outputs.firstWhere(
                  (o) => o.id == widget.outputId,
                );
                setState(() {
                  _loadOutputData(output);
                  _isLoadingData = false; // Mark loading as complete
                });
              } catch (e) {
                debugPrint('Output with ID ${widget.outputId} not found: $e');
                setState(() => _isLoadingData = false);
              }
            }
          },
        ),
        BlocListener<OutputTypeBloc, OutputTypeState>(
          listener: (context, state) {
            // Auto-select the first default OutputType when creating a new output
            if (state is OutputTypeLoaded && !isEditing && _selectedOutputTypeId == null) {
              try {
                final defaultType = state.outputTypes.firstWhere(
                  (type) => type.isDefault,
                );
                setState(() {
                  _selectedOutputTypeId = defaultType.id;
                });
              } catch (e) {
                // No default type found, do nothing
                debugPrint('No default OutputType found: $e');
              }
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
          title: Text(isEditing ? 'Edit Output' : 'New Output'),
        ),
        body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SearchableProductField(
              initialProduct: _selectedProduct,
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                  // Auto-fill measurement unit when product is selected
                  if (product != null) {
                    _selectedMeasurementUnitId = product.measurementUnitId;
                  }
                });
              },
              validator: (product) {
                if (product == null) {
                  return 'Please select a product';
                }
                return null;
              },
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
                  // Find the measurement unit name for display
                  final selectedUnit = state.measurementUnits.firstWhere(
                    (unit) => unit.id == _selectedMeasurementUnitId,
                    orElse: () => state.measurementUnits.first,
                  );

                  return TextFormField(
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Measurement Unit',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-filled from selected product',
                    ),
                    controller: TextEditingController(
                      text: _selectedMeasurementUnitId != null
                        ? '${selectedUnit.name} (${selectedUnit.acronym})'
                        : '',
                    ),
                    validator: (value) {
                      if (_selectedMeasurementUnitId == null) {
                        return 'Please select a product first';
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
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a total amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<OutputTypeBloc, OutputTypeState>(
              builder: (context, state) {
                if (state is OutputTypeLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedOutputTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Output Type',
                      border: OutlineInputBorder(),
                    ),
                    items: state.outputTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOutputTypeId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an output type';
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
              readOnly: true,
              onTap: () => _selectDateTime(context),
              decoration: InputDecoration(
                labelText: 'Date & Time',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () => _selectDateTime(context),
                  tooltip: 'Select date & time',
                ),
              ),
              controller: TextEditingController(
                text: DateFormat('MMM dd, yyyy HH:mm').format(_selectedDate),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Validate form before submitting
                if (_formKey.currentState?.validate() ?? false) {
                  _handleSubmit();
                }
              },
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

  Future<void> _selectDateTime(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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

      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product')),
        );
        return;
      }

      final now = DateTime.now();
      final output = Output(
        id: isEditing ? _loadedOutput!.id : const Uuid().v4(),
        userId: isEditing ? _loadedOutput!.userId : currentUser!.id,
        productId: _selectedProduct!.id,
        quantity: double.parse(_quantityController.text),
        measurementUnitId: _selectedMeasurementUnitId!,
        totalAmount: double.parse(_totalAmountController.text),
        outputTypeId: _selectedOutputTypeId!,
        date: _selectedDate,
        createdAt: isEditing ? _loadedOutput!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        context.read<OutputBloc>().add(UpdateOutput(output));
      } else {
        context.read<OutputBloc>().add(CreateOutput(output));
      }

      Navigator.of(context).pop();
    }
  }
}
