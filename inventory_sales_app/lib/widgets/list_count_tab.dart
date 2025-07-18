import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../blocs/inventory_bloc.dart';
import '../constants/app_colors.dart';
import '../models/inventory_item.dart';

class ListCountTab extends StatefulWidget {
  const ListCountTab({super.key});

  @override
  State<ListCountTab> createState() => _ListCountTabState();
}

class _ListCountTabState extends State<ListCountTab> {
  final _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (state is InventoryLoaded) {
                  _allItems = state.itemsToCount;
                  _filterItems();
                  
                  if (_filteredItems.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return _buildItemsList();
                }
                
                if (state is InventoryError) {
                  return _buildErrorState(state.message);
                }
                
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items to Count',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'All items pending inventory counting',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search items',
        prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: () {
                  _searchController.clear();
                  _filterItems();
                },
              )
            : null,
      ),
      onChanged: (_) => _filterItems(),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        _buildStatsRow(),
        const SizedBox(height: 16),
        Expanded(
          child: MasonryGridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              return _buildItemCard(_filteredItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final totalItems = _allItems.length;
    final pendingItems = _allItems.where((item) => item.status == CountingStatus.pending).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Items',
              totalItems.toString(),
              PhosphorIcons.package(),
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              'Pending',
              pendingItems.toString(),
              PhosphorIcons.clock(),
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.package(),
                    color: _getStatusColor(item.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.product.code,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Expected', '${item.expectedQuantity} ${item.product.unit ?? 'units'}'),
            if (item.location != null)
              _buildInfoRow('Location', item.location!),
            _buildInfoRow('Price', '\$${item.product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCountDialog(item),
                    icon: Icon(PhosphorIcons.plus(), size: 16),
                    label: const Text('Count'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeItem(item),
                  icon: Icon(PhosphorIcons.trash(), size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.listChecks(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No items to count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All items have been counted or\nno counting session is active',
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

  Color _getStatusColor(CountingStatus status) {
    switch (status) {
      case CountingStatus.pending:
        return AppColors.warning;
      case CountingStatus.counted:
        return AppColors.success;
      case CountingStatus.confirmed:
        return AppColors.primary;
    }
  }

  void _filterItems() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          return item.product.name.toLowerCase().contains(query) ||
              item.product.code.toLowerCase().contains(query) ||
              item.product.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showCountDialog(InventoryItem item) {
    final quantityController = TextEditingController(
      text: item.expectedQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Count ${item.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Expected: ${item.expectedQuantity} ${item.product.unit ?? 'units'}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Counted Quantity',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                Navigator.of(dialogContext).pop();
                
                context.read<InventoryBloc>().add(
                  InventoryCountItem(itemId: item.id, quantity: quantity),
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Count saved for ${item.product.name}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save Count'),
            ),
          ],
        );
      },
    );
  }

  void _removeItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Remove "${item.product.name}" from counting list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<InventoryBloc>().add(
                  InventoryRemoveItem(item.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}