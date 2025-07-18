import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

abstract class InventoryEvent {}

class InventoryLoadItems extends InventoryEvent {}

class InventoryLoadCountedItems extends InventoryEvent {}

class InventoryCountItem extends InventoryEvent {
  final String itemId;
  final int quantity;
  
  InventoryCountItem({required this.itemId, required this.quantity});
}

class InventoryUpdateItem extends InventoryEvent {
  final String itemId;
  final Map<String, dynamic> updates;
  
  InventoryUpdateItem({required this.itemId, required this.updates});
}

class InventoryRemoveItem extends InventoryEvent {
  final String itemId;
  
  InventoryRemoveItem(this.itemId);
}

class InventoryStartCount extends InventoryEvent {}

class InventorySendForCount extends InventoryEvent {
  final String productId;
  
  InventorySendForCount(this.productId);
}

abstract class InventoryState {}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> itemsToCount;
  final List<InventoryItem> countedItems;
  
  InventoryLoaded({
    required this.itemsToCount,
    required this.countedItems,
  });
}

class InventoryError extends InventoryState {
  final String message;
  
  InventoryError(this.message);
}

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final ApiService _apiService;

  InventoryBloc({required ApiService apiService})
      : _apiService = apiService,
        super(InventoryInitial()) {
    on<InventoryLoadItems>(_onLoadItems);
    on<InventoryLoadCountedItems>(_onLoadCountedItems);
    on<InventoryCountItem>(_onCountItem);
    on<InventoryUpdateItem>(_onUpdateItem);
    on<InventoryRemoveItem>(_onRemoveItem);
    on<InventoryStartCount>(_onStartCount);
    on<InventorySendForCount>(_onSendForCount);
  }

  Future<void> _onLoadItems(
    InventoryLoadItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    
    try {
      final itemsToCount = await _apiService.getItemsForCounting();
      final countedItems = await _apiService.getCountedItems();
      
      emit(InventoryLoaded(
        itemsToCount: itemsToCount,
        countedItems: countedItems,
      ));
    } catch (e) {
      emit(InventoryError('Error loading inventory items: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCountedItems(
    InventoryLoadCountedItems event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      final countedItems = await _apiService.getCountedItems();
      final currentState = state;
      
      if (currentState is InventoryLoaded) {
        emit(InventoryLoaded(
          itemsToCount: currentState.itemsToCount,
          countedItems: countedItems,
        ));
      }
    } catch (e) {
      emit(InventoryError('Error loading counted items: ${e.toString()}'));
    }
  }

  Future<void> _onCountItem(
    InventoryCountItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.updateInventoryCount(event.itemId, event.quantity);
      add(InventoryLoadItems());
    } catch (e) {
      emit(InventoryError('Error counting item: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateItem(
    InventoryUpdateItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.updateItemCounting(event.itemId, event.updates);
      add(InventoryLoadItems());
    } catch (e) {
      emit(InventoryError('Error updating item: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveItem(
    InventoryRemoveItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.removeItemFromCounting(event.itemId);
      add(InventoryLoadItems());
    } catch (e) {
      emit(InventoryError('Error removing item: ${e.toString()}'));
    }
  }

  Future<void> _onStartCount(
    InventoryStartCount event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.startInventoryCount();
      add(InventoryLoadItems());
    } catch (e) {
      emit(InventoryError('Error starting inventory count: ${e.toString()}'));
    }
  }

  Future<void> _onSendForCount(
    InventorySendForCount event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _apiService.sendItemForCounting(event.productId);
      add(InventoryLoadItems());
    } catch (e) {
      emit(InventoryError('Error sending item for count: ${e.toString()}'));
    }
  }
}