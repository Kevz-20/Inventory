import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/forgot_pin_screen.dart';
import 'ui/screens/create_account_screen.dart';
import 'ui/screens/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/create_account': (context) => const CreateAccountScreen(),
        '/forgot_pin': (context) => const ForgotPinScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
