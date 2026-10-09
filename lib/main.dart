import 'package:flutter/material.dart';

import 'screens/training_screen.dart';
import 'screens/odds_training_screen.dart';

void main() {
  runApp(const PokerTrainerApp());
}

class PokerTrainerApp extends StatelessWidget {
  const PokerTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poker Trainer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TrainingScreen(),
    OddsTrainingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Opening Range',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Odds & Equity',
          ),
        ],
      ),
    );
  }
}