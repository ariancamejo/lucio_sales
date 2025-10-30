import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/debouncer.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import 'product_form_screen.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  final bool? activeFilter;
  final double? minPrice;
  final double? maxPrice;
  final double? minQuantity;
  final double? maxQuantity;
  final double? minCost;
  final double? maxCost;

  ProductSearchDelegate({
    this.activeFilter,
    this.minPrice,
    this.maxPrice,
    this.minQuantity,
    this.maxQuantity,
    this.minCost,
    this.maxCost,
  });

  @override
  String get searchFieldLabel => 'Search by name or code...';

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
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a product name or code'),
      );
    }

    context.read<ProductBloc>().add(
          SearchAndFilterProducts(
            searchQuery: query,
            activeFilter: activeFilter,
            minPrice: minPrice,
            maxPrice: maxPrice,
            minQuantity: minQuantity,
            maxQuantity: maxQuantity,
            minCost: minCost,
            maxCost: maxCost,
          ),
        );

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductLoaded) {
          final products = state.products;

          if (products.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.active ? Colors.green : Colors.grey,
                  child: Text(
                    product.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(
                  'Quantity: ${product.quantity} | Price: \$${product.price.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(
                          product: product,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () => close(context, product),
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
        child: Text('Enter a product name or code to search'),
      );
    }

    // Use debouncer to delay search while user is typing
    _debouncer.run(() {
      context.read<ProductBloc>().add(
            SearchAndFilterProducts(
              searchQuery: query,
              activeFilter: activeFilter,
              minPrice: minPrice,
              maxPrice: maxPrice,
              minQuantity: minQuantity,
              maxQuantity: maxQuantity,
              minCost: minCost,
              maxCost: maxCost,
            ),
          );
    });

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductLoaded) {
          final products = state.products;

          if (products.isEmpty) {
            return const Center(
              child: Text('No products found'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.active ? Colors.green : Colors.grey,
                  child: Text(
                    product.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(
                  'Quantity: ${product.quantity} | Price: \$${product.price.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(
                          product: product,
                        ),
                      ),
                    );
                  },
                ),
                onTap: () => close(context, product),
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
