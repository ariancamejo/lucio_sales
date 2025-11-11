import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/output_type.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';
import '../../blocs/output_type/output_type_state.dart';

class OutputTypeFormScreen extends StatefulWidget {
  /// Output Type ID for editing (from route parameter)
  final String? outputTypeId;

  const OutputTypeFormScreen({
    super.key,
    this.outputTypeId,
  });

  @override
  State<OutputTypeFormScreen> createState() => _OutputTypeFormScreenState();
}

class _OutputTypeFormScreenState extends State<OutputTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  OutputType? _loadedType;
  bool _isDefault = false;
  bool _isSale = true;

  bool get isEditing => widget.outputTypeId != null;

  @override
  void initState() {
    super.initState();
    if (widget.outputTypeId != null) {
      context.read<OutputTypeBloc>().add(LoadOutputTypes());
    }
  }

  void _loadTypeData(OutputType type) {
    _nameController.text = type.name;
    _isDefault = type.isDefault;
    _isSale = type.isSale;
    _loadedType = type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OutputTypeBloc, OutputTypeState>(
      listener: (context, state) {
        if (state is OutputTypeLoaded && widget.outputTypeId != null && _loadedType == null) {
          try {
            final type = state.outputTypes.firstWhere(
              (t) => t.id == widget.outputTypeId,
            );
            setState(() {
              _loadTypeData(type);
            });
          } catch (e) {
            debugPrint('OutputType with ID ${widget.outputTypeId} not found: $e');
          }
        }
      },
      child: Scaffold(
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
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Is Sale'),
                      subtitle: const Text('Include this type in sales reports'),
                      value: _isSale,
                      onChanged: (value) {
                        setState(() => _isSale = value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Default Type'),
                      subtitle: const Text('Use this type by default for new outputs'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() => _isDefault = value);
                      },
                    ),
                  ],
                ),
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
      final outputType = OutputType(
        id: isEditing ? _loadedType!.id : const Uuid().v4(),
        userId: isEditing ? _loadedType!.userId : currentUser!.id,
        name: _nameController.text.trim(),
        isDefault: _isDefault,
        isSale: _isSale,
        createdAt: isEditing ? _loadedType!.createdAt : now,
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
