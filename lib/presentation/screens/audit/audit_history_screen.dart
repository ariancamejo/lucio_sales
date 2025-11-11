import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/services/audit_service.dart';
import '../../blocs/audit/audit_bloc.dart';
import '../../blocs/audit/audit_event.dart';
import '../../blocs/audit/audit_state.dart';

class AuditHistoryScreen extends StatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  AuditBloc? _bloc;
  AuditService? _auditService;
  int _currentPage = 1;
  static const int _pageSize = 20;

  String? _selectedEntityType;
  String? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _syncedFilter;

  final List<String> _entityTypes = [
    'All',
    'product',
    'output',
    'product_entry',
    'measurement_unit',
    'output_type',
  ];

  final List<String> _actions = [
    'All',
    'create',
    'update',
    'delete',
  ];

  @override
  void initState() {
    super.initState();
    // AuditService only available on native platforms
    if (PlatformInfo.isNative) {
      try {
        _auditService = sl<AuditService>();
        _bloc = AuditBloc(auditService: _auditService!);
        _loadPage(_currentPage);
      } catch (e) {
        // Service not available
        debugPrint('AuditService not available: $e');
      }
    }
    // On web, audit history not available
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show message when service is not available
    if (_auditService == null || _bloc == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Audit History Not Available',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Audit history is only available on native platforms (desktop/mobile).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _bloc!,
      child: Scaffold(
        body: BlocBuilder<AuditBloc, AuditState>(
          builder: (context, state) {
            if (state is AuditLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AuditError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${state.message}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _loadPage(_currentPage),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is AuditPaginatedLoaded) {
              if (state.history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No audit history found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _loadPage(_currentPage);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: state.history.length,
                        itemBuilder: (context, index) {
                          final item = state.history[index];
                          return _buildAuditCard(context, item);
                        },
                      ),
                    ),
                  ),
                  if (state.totalPages > 1)
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
                              'Page $_currentPage of ${state.totalPages} (${state.totalItems} items)',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadPage(_currentPage);
                                      }
                                    : null,
                              ),
                              Text('$_currentPage'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < state.totalPages
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
              );
            }

            return const Center(child: Text('Initializing...'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFilterDialog(context),
          child: const Icon(Icons.filter_list),
        ),
      ),
    );
  }

  void _loadPage(int page) {
    if (_bloc == null) return;
    _bloc!.add(
      LoadAuditHistoryPaginated(
        page: page,
        pageSize: _pageSize,
        entityType: _selectedEntityType,
        action: _selectedAction,
        startDate: _startDate,
        endDate: _endDate,
        synced: _syncedFilter,
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, UserHistoryData item) {
    final actionColor = _getActionColor(item.action);
    final actionIcon = _getActionIcon(item.action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withValues(alpha: 0.2),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Text(
          '${_capitalizeFirst(item.action)} ${_capitalizeFirst(item.entityType)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Entity ID: ${item.entityId.length > 8 ? item.entityId.substring(0, 8) : item.entityId}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy - HH:mm:ss').format(item.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (!item.synced) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Not synced',
                    child: Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('User ID', item.userId),
                const SizedBox(height: 8),
                _buildDetailRow('Entity Type', item.entityType),
                const SizedBox(height: 8),
                _buildDetailRow('Action', item.action),
                const SizedBox(height: 8),
                _buildDetailRow('Full Entity ID', item.entityId),
                const SizedBox(height: 16),
                if (item.changes != null) ...[
                  const Text(
                    'Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildJsonView(item.changes!),
                  const SizedBox(height: 16),
                ],
                if (item.oldValues != null) ...[
                  const Text(
                    'Old Values:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildJsonView(item.oldValues!),
                  const SizedBox(height: 16),
                ],
                if (item.newValues != null) ...[
                  const Text(
                    'New Values:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildJsonView(item.newValues!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJsonView(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatValue(entry.value),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      return Text(
        jsonString,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
  }

  String _formatValue(dynamic value) {
    if (value is Map) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.help_outline;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
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
                          _selectedEntityType = null;
                          _selectedAction = null;
                          _startDate = null;
                          _endDate = null;
                          _syncedFilter = null;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Entity Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedEntityType ?? 'All',
                  items: _entityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedEntityType = value == 'All' ? null : value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Action', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAction ?? 'All',
                  items: _actions.map((action) {
                    return DropdownMenuItem(
                      value: action,
                      child: Text(action),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedAction = value == 'All' ? null : value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Sync Status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Synced')),
                    ButtonSegment(value: false, label: Text('Not Synced')),
                  ],
                  selected: {_syncedFilter},
                  onSelectionChanged: (Set<bool?> newSelection) {
                    setDialogState(() {
                      _syncedFilter = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('Start Date', style: Theme.of(context).textTheme.titleMedium),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Not set',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() {
                              _startDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('End Date', style: Theme.of(context).textTheme.titleMedium),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _endDate != null
                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                        : 'Not set',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() {
                              _endDate = null;
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _currentPage = 1);
                        _loadPage(1);
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
