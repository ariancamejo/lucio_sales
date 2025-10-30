import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/measurement_unit.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';

class MeasurementUnitFormScreen extends StatefulWidget {
  final MeasurementUnit? measurementUnit;

  const MeasurementUnitFormScreen({
    super.key,
    this.measurementUnit,
  });

  @override
  State<MeasurementUnitFormScreen> createState() => _MeasurementUnitFormScreenState();
}

class _MeasurementUnitFormScreenState extends State<MeasurementUnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _acronymController = TextEditingController();

  bool get isEditing => widget.measurementUnit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.measurementUnit!.name;
      _acronymController.text = widget.measurementUnit!.acronym;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _acronymController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        id: isEditing ? widget.measurementUnit!.id : const Uuid().v4(),
        userId: isEditing ? widget.measurementUnit!.userId : currentUser!.id,
        name: _nameController.text.trim(),
        acronym: _acronymController.text.trim(),
        createdAt: isEditing ? widget.measurementUnit!.createdAt : now,
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
