import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
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
        '/login': (context) => const PinLoginPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
