import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'HomeScreen.dart';
import 'theme/app_theme.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Ứng dụng chuyển đổi',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: AppTheme.darkBackground,
        colorScheme: base.colorScheme.copyWith(
          primary: Colors.lightBlueAccent,
          secondary: const Color(0xFFF97386),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      home: const HomeScreen(),);
  }
}



