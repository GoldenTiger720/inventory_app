import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/api_service.dart';

abstract class OrderEvent {}

class OrderLoadItems extends OrderEvent {}

class OrderSearchItems extends OrderEvent {
  final String query;
  
  OrderSearchItems(this.query);
}

class OrderCreateNew extends OrderEvent {}

class OrderAddProduct extends OrderEvent {
  final Product product;
  final int quantity;
  
  OrderAddProduct({required this.product, required this.quantity});
}

class OrderRemoveProduct extends OrderEvent {
  final String productId;
  
  OrderRemoveProduct(this.productId);
}

class OrderUpdateQuantity extends OrderEvent {
  final String productId;
  final int quantity;
  
  OrderUpdateQuantity({required this.productId, required this.quantity});
}

class OrderClear extends OrderEvent {}

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  final Order? currentOrder;
  
  OrderLoaded({required this.orders, this.currentOrder});
}

class OrderUpdated extends OrderState {
  final List<OrderItem> items;
  final double total;
  
  OrderUpdated({required this.items, required this.total});
}

class OrderError extends OrderState {
  final String message;
  
  OrderError(this.message);
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService _apiService;
  final List<OrderItem> _items = [];
  final List<Order> _orders = [];

  OrderBloc({required ApiService apiService})
      : _apiService = apiService,
        super(OrderInitial()) {
    on<OrderLoadItems>(_onLoadItems);
    on<OrderSearchItems>(_onSearchItems);
    on<OrderCreateNew>(_onCreateNew);
    on<OrderAddProduct>(_onAddProduct);
    on<OrderRemoveProduct>(_onRemoveProduct);
    on<OrderUpdateQuantity>(_onUpdateQuantity);
    on<OrderClear>(_onClear);
  }

  Future<void> _onLoadItems(
    OrderLoadItems event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      // Mock data for demonstration
      final mockOrders = [
        Order(
          id: '1',
          customerName: 'John Doe',
          status: 'completed',
          total: 156.99,
          items: [],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Order(
          id: '2',
          customerName: 'Jane Smith',
          status: 'pending',
          total: 89.50,
          items: [],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Order(
          id: '3',
          customerName: 'Bob Johnson',
          status: 'pending',
          total: 234.75,
          items: [],
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
      
      _orders.clear();
      _orders.addAll(mockOrders);
      
      emit(OrderLoaded(orders: List.from(_orders)));
    } catch (e) {
      emit(OrderError('Error loading orders: ${e.toString()}'));
    }
  }

  Future<void> _onSearchItems(
    OrderSearchItems event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      final filteredOrders = _orders.where((order) {
        return order.customerName.toLowerCase().contains(event.query.toLowerCase()) ||
               order.id.contains(event.query);
      }).toList();
      
      emit(OrderLoaded(orders: filteredOrders));
    } catch (e) {
      emit(OrderError('Error searching orders: ${e.toString()}'));
    }
  }

  Future<void> _onCreateNew(
    OrderCreateNew event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      final newOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: 'New Customer',
        status: 'pending',
        total: 0.0,
        items: [],
        createdAt: DateTime.now(),
      );
      
      _orders.insert(0, newOrder);
      
      emit(OrderLoaded(orders: List.from(_orders), currentOrder: newOrder));
    } catch (e) {
      emit(OrderError('Error creating new order: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(
    OrderAddProduct event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      await _apiService.addToOrder(event.product.code, event.quantity);
      
      final existingIndex = _items.indexWhere(
        (item) => item.product.id == event.product.id,
      );
      
      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + event.quantity,
        );
      } else {
        final newItem = OrderItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: event.product,
          quantity: event.quantity,
          unitPrice: event.product.price,
          addedAt: DateTime.now(),
        );
        _items.add(newItem);
      }
      
      final total = _items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      
      emit(OrderUpdated(items: List.from(_items), total: total));
    } catch (e) {
      emit(OrderError('Error adding product to order: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveProduct(
    OrderRemoveProduct event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      await _apiService.removeFromOrder(event.productId);
      
      _items.removeWhere((item) => item.product.id == event.productId);
      
      final total = _items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      
      emit(OrderUpdated(items: List.from(_items), total: total));
    } catch (e) {
      emit(OrderError('Error removing product from order: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateQuantity(
    OrderUpdateQuantity event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    
    try {
      final itemIndex = _items.indexWhere(
        (item) => item.product.id == event.productId,
      );
      
      if (itemIndex >= 0) {
        if (event.quantity <= 0) {
          add(OrderRemoveProduct(event.productId));
          return;
        }
        
        _items[itemIndex] = _items[itemIndex].copyWith(
          quantity: event.quantity,
        );
        
        final total = _items.fold<double>(
          0,
          (sum, item) => sum + item.totalPrice,
        );
        
        emit(OrderUpdated(items: List.from(_items), total: total));
      }
    } catch (e) {
      emit(OrderError('Error updating quantity: ${e.toString()}'));
    }
  }

  Future<void> _onClear(
    OrderClear event,
    Emitter<OrderState> emit,
  ) async {
    _items.clear();
    emit(OrderInitial());
  }
}