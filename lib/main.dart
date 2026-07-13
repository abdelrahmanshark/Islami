import 'package:flutter/material.dart';
import 'package:islami/ui/home/home_screen.dart';
import 'package:islami/utils/app_routes.dart';

void main() {
  runApp(Islami());
}

class Islami extends StatelessWidget {
  const Islami({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: AppRoutes.homeRouteName,
      routes: {AppRoutes.homeRouteName: (context) => HomeScreen()},
    );
  }
}
