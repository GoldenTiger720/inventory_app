import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../blocs/inventory_bloc.dart';
import '../constants/app_colors.dart';
import '../models/inventory_item.dart';

class CountedItemsTab extends StatefulWidget {
  const CountedItemsTab({super.key});

  @override
  State<CountedItemsTab> createState() => _CountedItemsTabState();
}

class _CountedItemsTabState extends State<CountedItemsTab> {
  final _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        _filterItems();
      }
    });
  }

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
                  _allItems = state.countedItems;
                  
                  // Defer the filtering to after the build phase
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _filterItems();
                    }
                  });
                  
                  // Use the filtered items if available, otherwise use all items
                  final itemsToShow = _filteredItems.isEmpty && _searchController.text.isEmpty
                      ? _allItems
                      : _filteredItems;
                  
                  if (itemsToShow.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  // Update _filteredItems for display without setState
                  _filteredItems = itemsToShow;
                  
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
          'Counted Items',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Items that have been counted',
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
        labelText: 'Search counted items',
        prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
      ),
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
    final totalCounted = _allItems.length;
    final withVariance = _allItems.where((item) => item.hasVariance).length;
    final totalVariance = _allItems.fold<int>(0, (sum, item) => sum + item.variance.abs());
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Counted',
                  totalCounted.toString(),
                  PhosphorIcons.checkCircle(),
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'With Variance',
                  withVariance.toString(),
                  PhosphorIcons.warning(),
                  AppColors.warning,
                ),
              ),
            ],
          ),
          if (totalVariance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(),
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total variance: $totalVariance units',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final hasVariance = item.hasVariance;
    final varianceColor = item.variance > 0 ? AppColors.success : AppColors.error;
    
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.checkCircle(),
                    color: AppColors.success,
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
            _buildInfoRow('Expected', '${item.expectedQuantity}'),
            _buildInfoRow('Counted', '${item.countedQuantity ?? 0}'),
            if (hasVariance)
              _buildInfoRow(
                'Variance',
                '${item.variance > 0 ? '+' : ''}${item.variance}',
                color: varianceColor,
              ),
            if (item.countedAt != null)
              _buildInfoRow(
                'Counted At',
                _formatDateTime(item.countedAt!),
              ),
            const SizedBox(height: 12),
            if (hasVariance)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: varianceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.variance > 0 
                          ? PhosphorIcons.trendUp()
                          : PhosphorIcons.trendDown(),
                      color: varianceColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.variance > 0 ? 'Surplus' : 'Shortage',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: varianceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRecountDialog(item),
                    icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 16),
                    label: const Text('Recount'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeCountedItem(item),
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: color != null ? FontWeight.w500 : null,
              ),
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
            PhosphorIcons.checkCircle(),
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No items counted yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items will appear here after\nthey have been counted',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  void _showRecountDialog(InventoryItem item) {
    final quantityController = TextEditingController(
      text: item.countedQuantity?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Recount ${item.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Expected: ${item.expectedQuantity} ${item.product.unit ?? 'units'}'),
              Text('Previous count: ${item.countedQuantity ?? 0} ${item.product.unit ?? 'units'}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Count',
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
                    content: Text('Recount saved for ${item.product.name}'),
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

  void _removeCountedItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Count'),
          content: Text('Remove count for "${item.product.name}"? This will move the item back to the counting list.'),
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