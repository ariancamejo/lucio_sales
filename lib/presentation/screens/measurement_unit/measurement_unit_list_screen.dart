import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../blocs/measurement_unit/measurement_unit_event.dart';
import '../../blocs/measurement_unit/measurement_unit_state.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_event.dart';

class MeasurementUnitListScreen extends StatefulWidget {
  const MeasurementUnitListScreen({super.key});

  @override
  State<MeasurementUnitListScreen> createState() => _MeasurementUnitListScreenState();
}

class _MeasurementUnitListScreenState extends State<MeasurementUnitListScreen> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  void _loadPage(int page) {
    context.read<MeasurementUnitBloc>().add(
      LoadMeasurementUnitsPaginated(page: page, pageSize: _pageSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/measurement-units/new');
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<MeasurementUnitBloc, MeasurementUnitState>(
        listener: (context, state) {
          if (state is MeasurementUnitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MeasurementUnitOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MeasurementUnitPaginatedLoaded) {
            // Sync local page state with bloc state
            if (_currentPage != state.currentPage) {
              setState(() {
                _currentPage = state.currentPage;
              });
            }
          }
        },
        builder: (context, state) {
          if (state is MeasurementUnitLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MeasurementUnitLoaded || state is MeasurementUnitPaginatedLoaded) {
            final measurementUnits = state is MeasurementUnitLoaded
                ? state.measurementUnits
                : (state as MeasurementUnitPaginatedLoaded).measurementUnits;
            final currentPage = state is MeasurementUnitPaginatedLoaded ? state.currentPage : 1;
            final totalPages = state is MeasurementUnitPaginatedLoaded ? state.totalPages : 1;
            final totalItems = state is MeasurementUnitPaginatedLoaded ? state.totalItems : measurementUnits.length;

            if (measurementUnits.isEmpty) {
              return const Center(
                child: Text('No measurement units found.\nTap + to add one.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadPage(_currentPage);
              },
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 800 ? 3
                            : constraints.maxWidth > 600 ? 2
                            : 1;

                        if (crossAxisCount == 1) {
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: measurementUnits.length,
                            itemBuilder: (context, index) {
                              final unit = measurementUnits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildMeasurementUnitCard(context, unit, withSwipe: true),
                              );
                            },
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3,
                          ),
                          itemCount: measurementUnits.length,
                          itemBuilder: (context, index) => _buildMeasurementUnitCard(context, measurementUnits[index]),
                        );
                      },
                    ),
                  ),
                  if (state is MeasurementUnitPaginatedLoaded && totalPages > 1)
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
                              'Page $currentPage of $totalPages ($totalItems items)',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: currentPage > 1
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadPage(_currentPage);
                                      }
                                    : null,
                              ),
                              Text('$currentPage'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < totalPages
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
              ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildMeasurementUnitCard(BuildContext context, unit, {bool withSwipe = false}) {
    final cardContent = Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/measurement-units/${unit.id}/edit');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple,
                child: Text(
                  unit.acronym.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unit.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.acronym,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (!unit.synced)
                Tooltip(
                  message: 'Not synced - Tap to sync',
                  child: InkWell(
                    onTap: () {
                      context.read<SyncBloc>().add(StartSync());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              if (!withSwipe) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    context.push('/measurement-units/${unit.id}/edit');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () {
                    _showDeleteDialog(context, unit.id, unit.name);
                  },
                ),
              ] else
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );

    if (!withSwipe) {
      return cardContent;
    }

    return Dismissible(
      key: Key(unit.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete Measurement Unit'),
              content: Text('Are you sure you want to delete "${unit.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          context.push('/measurement-units/${unit.id}/edit');
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<MeasurementUnitBloc>().add(DeleteMeasurementUnit(unit.id));
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      child: cardContent,
    );
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Measurement Unit'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MeasurementUnitBloc>().add(DeleteMeasurementUnit(id));
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
