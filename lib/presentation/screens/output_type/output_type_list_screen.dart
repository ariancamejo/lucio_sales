import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/output_type/output_type_bloc.dart';
import '../../blocs/output_type/output_type_event.dart';
import '../../blocs/output_type/output_type_state.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../blocs/sync/sync_event.dart';

class OutputTypeListScreen extends StatefulWidget {
  const OutputTypeListScreen({super.key});

  @override
  State<OutputTypeListScreen> createState() => _OutputTypeListScreenState();
}

class _OutputTypeListScreenState extends State<OutputTypeListScreen> {
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  void _loadPage(int page) {
    context.read<OutputTypeBloc>().add(
      LoadOutputTypesPaginated(page: page, pageSize: _pageSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/output-types/new');
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<OutputTypeBloc, OutputTypeState>(
        listener: (context, state) {
          if (state is OutputTypeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is OutputTypeOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is OutputTypePaginatedLoaded) {
            // Sync local page state with bloc state
            if (_currentPage != state.currentPage) {
              setState(() {
                _currentPage = state.currentPage;
              });
            }
          }
        },
        builder: (context, state) {
          if (state is OutputTypeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OutputTypeLoaded || state is OutputTypePaginatedLoaded) {
            final outputTypes = state is OutputTypeLoaded
                ? state.outputTypes
                : (state as OutputTypePaginatedLoaded).outputTypes;
            final currentPage = state is OutputTypePaginatedLoaded ? state.currentPage : 1;
            final totalPages = state is OutputTypePaginatedLoaded ? state.totalPages : 1;
            final totalItems = state is OutputTypePaginatedLoaded ? state.totalItems : outputTypes.length;

            if (outputTypes.isEmpty) {
              return const Center(
                child: Text('No output types found.\nTap + to add one.'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadPage(_currentPage);
              },
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: outputTypes.length,
                      itemBuilder: (context, index) {
                        final outputType = outputTypes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(outputType.id),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe left to delete
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Output Type'),
                                    content: Text('Are you sure you want to delete "${outputType.name}"?'),
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
                                context.push('/output-types/${outputType.id}/edit');
                                return false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                context.read<OutputTypeBloc>().add(DeleteOutputType(outputType.id));
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
                            child: Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  context.push('/output-types/${outputType.id}/edit');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.orange,
                                        child: Icon(
                                          Icons.category,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          outputType.name,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!outputType.synced)
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
                                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (state is OutputTypePaginatedLoaded && totalPages > 1)
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

}
