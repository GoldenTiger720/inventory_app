import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../blocs/product_bloc.dart';
import '../blocs/inventory_bloc.dart';
import '../constants/app_colors.dart';
import '../widgets/barcode_scanner.dart';
import '../models/product.dart';

class IndividualCountTab extends StatefulWidget {
  const IndividualCountTab({super.key});

  @override
  State<IndividualCountTab> createState() => _IndividualCountTabState();
}

class _IndividualCountTabState extends State<IndividualCountTab> {
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  Product? _currentProduct;

  @override
  void dispose() {
    _codeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Individual Count',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Count items one by one using product codes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
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
                  _currentProduct = state.product;
                  return _buildProductCountCard(state.product);
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
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Product Code',
            prefixIcon: Icon(PhosphorIcons.barcode()),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.camera()),
                  onPressed: _openBarcodeScanner,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.magnifyingGlass()),
                  onPressed: _searchProduct,
                ),
              ],
            ),
          ),
          onFieldSubmitted: (_) => _searchProduct(),
        ),
      ],
    );
  }

  Widget _buildProductCountCard(Product product) {
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
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.package(),
                      size: 32,
                      color: AppColors.secondary,
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
              _buildInfoRow('Current Stock', '${product.currentQuantity} ${product.unit ?? 'units'}'),
              _buildInfoRow('Price', '\$${product.price.toStringAsFixed(2)}'),
              if (product.location != null)
                _buildInfoRow('Location', product.location!),
              const SizedBox(height: 24),
              _buildCountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountSection() {
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
            'Count Quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => _adjustQuantity(-1),
                icon: Icon(PhosphorIcons.minus()),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Counted Quantity',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _adjustQuantity(1),
                icon: Icon(PhosphorIcons.plus()),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearCount,
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    final isLoading = state is InventoryLoading;
                    
                    return ElevatedButton(
                      onPressed: isLoading ? null : _saveCount,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Count'),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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
            PhosphorIcons.package(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to Count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a product code or scan a barcode\nto start counting inventory',
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
            'Product not found',
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
        ],
      ),
    );
  }

  void _openBarcodeScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BarcodeScanner(
          title: 'Scan Product Code',
          onScanResult: (String code) {
            _codeController.text = code;
            context.read<ProductBloc>().add(ProductSearchByCode(code));
          },
        ),
      ),
    );
  }

  void _searchProduct() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      context.read<ProductBloc>().add(ProductSearchByCode(code));
    }
  }

  void _adjustQuantity(int delta) {
    final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
    final newQuantity = (currentQuantity + delta).clamp(0, double.infinity).toInt();
    _quantityController.text = newQuantity.toString();
  }

  void _clearCount() {
    _quantityController.text = '0';
    _codeController.clear();
    _currentProduct = null;
    context.read<ProductBloc>().add(ProductClearSearch());
  }

  void _saveCount() {
    if (_currentProduct != null) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      
      // For individual counting, we use the product ID as the item ID
      context.read<InventoryBloc>().add(
        InventoryCountItem(itemId: _currentProduct!.id, quantity: quantity),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Count saved for ${_currentProduct!.name}'),
          backgroundColor: AppColors.success,
        ),
      );
      
      _clearCount();
    }
  }
}