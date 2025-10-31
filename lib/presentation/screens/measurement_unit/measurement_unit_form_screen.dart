import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/measurement_unit.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';
import '../../blocs/measurement_unit/measurement_unit_state.dart';

class MeasurementUnitFormScreen extends StatefulWidget {
  /// Measurement Unit ID for editing (from route parameter)
  final String? measurementUnitId;

  const MeasurementUnitFormScreen({
    super.key,
    this.measurementUnitId,
  });

  @override
  State<MeasurementUnitFormScreen> createState() => _MeasurementUnitFormScreenState();
}

class _MeasurementUnitFormScreenState extends State<MeasurementUnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _acronymController = TextEditingController();
  MeasurementUnit? _loadedUnit;

  bool get isEditing => widget.measurementUnitId != null;

  @override
  void initState() {
    super.initState();
    if (widget.measurementUnitId != null) {
      // Load the measurement unit from bloc
      context.read<MeasurementUnitBloc>().add(LoadMeasurementUnits());
    }
  }

  void _loadUnitData(MeasurementUnit unit) {
    _nameController.text = unit.name;
    _acronymController.text = unit.acronym;
    _loadedUnit = unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _acronymController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeasurementUnitBloc, MeasurementUnitState>(
      listener: (context, state) {
        if (state is MeasurementUnitLoaded && widget.measurementUnitId != null && _loadedUnit == null) {
          try {
            final unit = state.measurementUnits.firstWhere(
              (u) => u.id == widget.measurementUnitId,
            );
            setState(() {
              _loadUnitData(unit);
            });
          } catch (e) {
            debugPrint('MeasurementUnit with ID ${widget.measurementUnitId} not found: $e');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Measurement Unit' : 'New Measurement Unit'),
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
              controller: _acronymController,
              decoration: const InputDecoration(
                labelText: 'Acronym',
                border: OutlineInputBorder(),
                hintText: 'e.g., kg, L, pcs',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an acronym';
                }
                return null;
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

      final now = DateTime.now();
      final measurementUnit = MeasurementUnit(
        id: isEditing ? _loadedUnit!.id : const Uuid().v4(),
        userId: isEditing ? _loadedUnit!.userId : currentUser!.id,
        name: _nameController.text.trim(),
        acronym: _acronymController.text.trim(),
        createdAt: isEditing ? _loadedUnit!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        context.read<MeasurementUnitBloc>().add(UpdateMeasurementUnit(measurementUnit));
      } else {
        context.read<MeasurementUnitBloc>().add(CreateMeasurementUnit(measurementUnit));
      }

      Navigator.of(context).pop();
    }
  }
}
