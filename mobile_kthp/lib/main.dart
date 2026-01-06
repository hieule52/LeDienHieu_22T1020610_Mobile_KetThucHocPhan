import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/api_service.dart';
import 'data/repositories/product_repository.dart';
import 'features/products/controllers/product_controller.dart';
import 'features/products/pages/product_list_page.dart';
import 'features/cart/controllers/cart_controller.dart';
import 'features/auth/controllers/auth_controller.dart';

import 'features/address/controllers/address_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        Provider(create: (ctx) => ProductRepository(ctx.read<ApiService>())),
        ChangeNotifierProvider(
          create: (ctx) => ProductController(ctx.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(
          create: (_) => AddressController()..loadAddresses(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Le Dien Hieu',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00B14F), // Main Green
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            color: Color(0xFF00B14F),
            foregroundColor: Colors.white,
          ),
        ),
        home: const ProductListPage(),
      ),
    );
  }
}
