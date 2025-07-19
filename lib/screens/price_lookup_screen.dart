import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../blocs/product_bloc.dart';
import '../blocs/order_bloc.dart';
import '../constants/app_colors.dart';
import '../widgets/barcode_scanner.dart';
import '../models/product.dart';

class PriceLookupScreen extends StatefulWidget {
  const PriceLookupScreen({super.key});

  @override
  State<PriceLookupScreen> createState() => _PriceLookupScreenState();
}

class _PriceLookupScreenState extends State<PriceLookupScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Price Lookup'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.camera()),
            onPressed: _openBarcodeScanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchSection(),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (state is ProductFound) {
                    return _buildProductCard(state.product);
                  }
                  
                  if (state is ProductsFound) {
                    return _buildProductsList(state.products);
                  }
                  
                  if (state is ProductNotFound) {
                    return _buildEmptyState(state.message);
                  }
                  
                  if (state is ProductError) {
                    return _buildErrorState(state.message);
                  }
                  
                  return _buildInitialState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search by code or description',
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.camera()),
                  onPressed: _openBarcodeScanner,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.magnifyingGlass()),
                  onPressed: _performSearch,
                ),
              ],
            ),
          ),
          onFieldSubmitted: (_) => _performSearch(),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.package(),
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Code: ${product.code}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow('Description', product.description),
              _buildInfoRow('Price', '\$${product.price.toStringAsFixed(2)}'),
              _buildInfoRow('Stock', '${product.currentQuantity} ${product.unit ?? 'units'}'),
              if (product.location != null)
                _buildInfoRow('Location', product.location!),
              const SizedBox(height: 24),
              _buildOrderSection(product),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSection(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  final isLoading = state is OrderLoading;
                  
                  return ElevatedButton(
                    onPressed: isLoading ? null : () => _addToOrder(product),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Add'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                PhosphorIcons.package(),
                color: AppColors.primary,
              ),
            ),
            title: Text(product.name),
            subtitle: Text('${product.code} • \$${product.price.toStringAsFixed(2)}'),
            trailing: Icon(PhosphorIcons.caretRight()),
            onTap: () {
              context.read<ProductBloc>().add(ProductSearchByCode(product.code));
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.magnifyingGlass(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for products',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a product code or description\nor scan a barcode to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.package(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(ProductClearSearch());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _openBarcodeScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          onScanResult: (String code) {
            _searchController.text = code;
            context.read<ProductBloc>().add(ProductSearchByCode(code));
          },
        ),
      ),
    );
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(query)) {
        context.read<ProductBloc>().add(ProductSearchByCode(query));
      } else {
        context.read<ProductBloc>().add(ProductSearchByDescription(query));
      }
    }
  }

  void _addToOrder(Product product) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity > 0) {
      context.read<OrderBloc>().add(
        OrderAddProduct(product: product, quantity: quantity),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to order'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}