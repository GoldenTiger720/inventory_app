import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/product_bloc.dart';
import 'blocs/order_bloc.dart';
import 'blocs/inventory_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'constants/app_theme.dart';

void main() {
  runApp(const InventorySalesApp());
}

class InventorySalesApp extends StatelessWidget {
  const InventorySalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(
          create: (context) => ApiService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              apiService: context.read<ApiService>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider<InventoryBloc>(
            create: (context) => InventoryBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Inventory & Sales',
          theme: AppTheme.lightTheme,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (state is AuthAuthenticated) {
                return const DashboardScreen();
              }
              
              return const LoginScreen();
            },
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}