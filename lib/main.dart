import 'package:flutter/material.dart';
import 'ui/theme/f1_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const F1ManagerApp());
}

class F1ManagerApp extends StatelessWidget {
  const F1ManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Manager',
      debugShowCheckedModeBanner: false,
      theme: F1Theme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
