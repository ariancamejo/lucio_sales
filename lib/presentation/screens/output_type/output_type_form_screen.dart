import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/output_type.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';

class OutputTypeFormScreen extends StatefulWidget {
  final OutputType? outputType;

  const OutputTypeFormScreen({
    super.key,
    this.outputType,
  });

  @override
  State<OutputTypeFormScreen> createState() => _OutputTypeFormScreenState();
}

class _OutputTypeFormScreenState extends State<OutputTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool get isEditing => widget.outputType != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.outputType!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Output Type' : 'New Output Type'),
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
                hintText: 'e.g., Sale, Loss, Sample',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
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
      final outputType = OutputType(
        id: isEditing ? widget.outputType!.id : const Uuid().v4(),
        userId: isEditing ? widget.outputType!.userId : currentUser!.id,
        name: _nameController.text.trim(),
        createdAt: isEditing ? widget.outputType!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        context.read<OutputTypeBloc>().add(UpdateOutputType(outputType));
      } else {
        context.read<OutputTypeBloc>().add(CreateOutputType(outputType));
      }

      Navigator.of(context).pop();
    }
  }
}
