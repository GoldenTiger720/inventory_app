import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import 'database_helper.dart';

class ApiService {
  static const String baseUrl = 'https://your-sgw-api.com/api';
  late final Dio _dio;
  String? _accessToken;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String? _currentUserId;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _refreshToken();
            handler.reject(error);
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _accessToken = token;
  }

  Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken != null) {
      try {
        final response = await _dio.post('/auth/refresh', data: {
          'refresh_token': refreshToken,
        });
        
        if (response.statusCode == 200) {
          final newAccessToken = response.data['access_token'];
          await _saveToken(newAccessToken);
        }
      } catch (e) {
        await logout();
      }
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final user = await _databaseHelper.loginUser(email, password);
      
      if (user == null) {
        throw Exception('Invalid email or password');
      }
      
      await _saveToken(user.accessToken!);
      _currentUserId = user.id;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', user.refreshToken!);
      await prefs.setString('user_data', user.id);
      await prefs.setString('user_id', user.id);
      
      return user;
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final user = await _databaseHelper.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      
      if (user == null) {
        throw Exception('Failed to create user');
      }
      
      await _saveToken(user.accessToken!);
      _currentUserId = user.id;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', user.refreshToken!);
      await prefs.setString('user_data', user.id);
      await prefs.setString('user_id', user.id);
      
      return user;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        throw Exception('User already exists with this email');
      } else {
        throw Exception('Registration error: $e');
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _accessToken = null;
  }

  Future<Product> getProductByCode(String code) async {
    await _loadToken();
    try {
      final product = await _databaseHelper.getProductByCode(code);
      if (product == null) {
        throw Exception('Product not found');
      }
      return product;
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<List<Product>> searchProductsByDescription(String description) async {
    await _loadToken();
    try {
      final products = await _databaseHelper.searchProductsByDescription(description);
      return products;
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  Future<void> addToOrder(String productId, int quantity) async {
    await _loadToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      await _databaseHelper.addToOrderQueue(productId, quantity, userId);
    } catch (e) {
      throw Exception('Error adding to order: $e');
    }
  }

  Future<void> removeFromOrder(String orderId) async {
    await _loadToken();
    try {
      await _databaseHelper.removeFromOrderQueue(orderId);
    } catch (e) {
      throw Exception('Error removing from order: $e');
    }
  }

  Future<void> startInventoryCount() async {
    await _loadToken();
    try {
      // Mock implementation - just simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      // In a real app, this would make an API call
    } catch (e) {
      throw Exception('Error starting inventory count: $e');
    }
  }

  Future<void> updateInventoryCount(String itemId, int countedQuantity) async {
    await _loadToken();
    try {
      await _databaseHelper.updateInventoryCount(itemId, countedQuantity);
    } catch (e) {
      throw Exception('Error updating inventory count: $e');
    }
  }

  Future<void> deleteInventoryCount(String itemId) async {
    await _loadToken();
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error deleting inventory count: $e');
    }
  }

  Future<void> sendItemForCounting(String productId) async {
    await _loadToken();
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error sending item for counting: $e');
    }
  }

  Future<void> removeItemFromCounting(String itemId) async {
    await _loadToken();
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error removing item from counting: $e');
    }
  }

  Future<void> updateItemCounting(String itemId, Map<String, dynamic> updates) async {
    await _loadToken();
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error updating item counting: $e');
    }
  }

  Future<void> updateProductRegistration(String productId, Map<String, dynamic> updates) async {
    await _loadToken();
    try {
      await _databaseHelper.updateProduct(productId, updates);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<List<InventoryItem>> getItemsForCounting() async {
    await _loadToken();
    try {
      final items = await _databaseHelper.getInventoryItemsForCounting();
      return items;
    } catch (e) {
      throw Exception('Error fetching items for counting: $e');
    }
  }

  Future<List<InventoryItem>> getCountedItems() async {
    await _loadToken();
    try {
      final items = await _databaseHelper.getCountedItems();
      return items;
    } catch (e) {
      throw Exception('Error fetching counted items: $e');
    }
  }
}