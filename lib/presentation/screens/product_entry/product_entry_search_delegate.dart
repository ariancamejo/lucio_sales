import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/debouncer.dart';
import '../../../domain/entities/product_entry.dart';
import '../../blocs/product_entry/product_entry_bloc.dart';
import '../../blocs/product_entry/product_entry_event.dart';
import '../../blocs/product_entry/product_entry_state.dart';

class ProductEntrySearchDelegate extends SearchDelegate<ProductEntry?> {
  final int currentPage;
  final int pageSize;
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  final String? productIdFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minQuantity;
  final double? maxQuantity;

  ProductEntrySearchDelegate({
    this.currentPage = 1,
    this.pageSize = 10,
    this.productIdFilter,
    this.startDate,
    this.endDate,
    this.minQuantity,
    this.maxQuantity,
  });

  @override
  String get searchFieldLabel => 'Search by product name...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // Reload paginated list when closing search
        context.read<ProductEntryBloc>().add(
              LoadProductEntriesPaginated(page: currentPage, pageSize: pageSize),
            );
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a product name'),
      );
    }

    context.read<ProductEntryBloc>().add(
          SearchAndFilterProductEntries(
            searchQuery: query,
            productIdFilter: productIdFilter,
            startDate: startDate,
            endDate: endDate,
            minQuantity: minQuantity,
            maxQuantity: maxQuantity,
          ),
        );

    return BlocBuilder<ProductEntryBloc, ProductEntryState>(
      builder: (context, state) {
        if (state is ProductEntryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductEntryLoaded) {
          final entries = state.productEntries;

          if (entries.isEmpty) {
            return const Center(
              child: Text('No entries found'),
            );
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    entry.quantity.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(entry.product?.name ?? 'Unknown Product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${entry.quantity}'),
                    Text('Date: ${dateFormat.format(entry.date)}'),
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      Text(
                        entry.notes!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    context.push('/stock-entries/${entry.id}/edit');
                  },
                ),
                onTap: () => close(context, entry),
              );
            },
          );
        }

        return const Center(
          child: Text('Something went wrong'),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a product name to search'),
      );
    }

    // Use debouncer to delay search while user is typing
    _debouncer.run(() {
      context.read<ProductEntryBloc>().add(
            SearchAndFilterProductEntries(
              searchQuery: query,
              productIdFilter: productIdFilter,
              startDate: startDate,
              endDate: endDate,
              minQuantity: minQuantity,
              maxQuantity: maxQuantity,
            ),
          );
    });

    return BlocBuilder<ProductEntryBloc, ProductEntryState>(
      builder: (context, state) {
        if (state is ProductEntryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductEntryLoaded) {
          final entries = state.productEntries;

          if (entries.isEmpty) {
            return const Center(
              child: Text('No entries found'),
            );
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    entry.quantity.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(entry.product?.name ?? 'Unknown Product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${entry.quantity}'),
                    Text('Date: ${dateFormat.format(entry.date)}'),
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      Text(
                        entry.notes!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    context.push('/stock-entries/${entry.id}/edit');
                  },
                ),
                onTap: () => close(context, entry),
              );
            },
          );
        }

        return const Center(
          child: Text('Something went wrong'),
        );
      },
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
