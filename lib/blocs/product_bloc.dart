import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../services/api_service.dart';

abstract class ProductEvent {}

class ProductSearchByCode extends ProductEvent {
  final String code;
  ProductSearchByCode(this.code);
}

class ProductSearchByDescription extends ProductEvent {
  final String description;
  ProductSearchByDescription(this.description);
}

class ProductClearSearch extends ProductEvent {}

abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductFound extends ProductState {
  final Product product;
  ProductFound(this.product);
}

class ProductsFound extends ProductState {
  final List<Product> products;
  ProductsFound(this.products);
}

class ProductNotFound extends ProductState {
  final String message;
  ProductNotFound(this.message);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiService _apiService;

  ProductBloc({required ApiService apiService})
      : _apiService = apiService,
        super(ProductInitial()) {
    on<ProductSearchByCode>(_onSearchByCode);
    on<ProductSearchByDescription>(_onSearchByDescription);
    on<ProductClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchByCode(
    ProductSearchByCode event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    
    try {
      final product = await _apiService.getProductByCode(event.code);
      emit(ProductFound(product));
    } catch (e) {
      if (e.toString().contains('not found')) {
        emit(ProductNotFound('Product with code "${event.code}" not found'));
      } else {
        emit(ProductError('Error searching product: ${e.toString()}'));
      }
    }
  }

  Future<void> _onSearchByDescription(
    ProductSearchByDescription event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    
    try {
      final products = await _apiService.searchProductsByDescription(event.description);
      if (products.isEmpty) {
        emit(ProductNotFound('No products found for "${event.description}"'));
      } else {
        emit(ProductsFound(products));
      }
    } catch (e) {
      emit(ProductError('Error searching products: ${e.toString()}'));
    }
  }

  Future<void> _onClearSearch(
    ProductClearSearch event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductInitial());
  }
}