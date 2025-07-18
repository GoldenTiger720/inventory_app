import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../blocs/inventory_bloc.dart';
import '../constants/app_colors.dart';
import '../widgets/individual_count_tab.dart';
import '../widgets/list_count_tab.dart';
import '../widgets/counted_items_tab.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<InventoryBloc>().add(InventoryLoadItems());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Count'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(PhosphorIcons.package()),
              text: 'Individual',
            ),
            Tab(
              icon: Icon(PhosphorIcons.list()),
              text: 'To Count',
            ),
            Tab(
              icon: Icon(PhosphorIcons.checkCircle()),
              text: 'Counted',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plus()),
            onPressed: _showStartCountDialog,
          ),
        ],
      ),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            IndividualCountTab(),
            ListCountTab(),
            CountedItemsTab(),
          ],
        ),
      ),
    );
  }

  void _showStartCountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Inventory Count'),
          content: const Text(
            'This will initialize a new inventory counting session. Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<InventoryBloc>().add(InventoryStartCount());
              },
              child: const Text('Start Count'),
            ),
          ],
        );
      },
    );
  }
}