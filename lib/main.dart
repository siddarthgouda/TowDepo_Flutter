import 'package:flutter/material.dart';
import 'package:fluttertfirst/pages/checkout_page.dart';
import 'package:fluttertfirst/pages/wishlist_page.dart';
import 'package:provider/provider.dart';
import '../states/app_state.dart';
import '../states/main_shell.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/nearby_products_screen.dart';


void main() {
  // Provide AppState to the whole app
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowDepo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey.shade100,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),

      // ALWAYS START WITH HOME VIA MainShell
      home: const MainShell(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/nearby-products': (context) => const NearbyProductsScreen(),
        '/wishlist': (context) => const WishlistPage(),
        '/checkout' :(context) => const CheckoutPage(cartItems: [],),
      },
    );
  }
}

