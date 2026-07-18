import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/workout_loop_screen.dart';
import 'widgets/app_bottom_navigation.dart';

void main() {
  runApp(const FitTracerApp());
}

class FitTracerApp extends StatelessWidget {
  const FitTracerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MR FitTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      DashboardScreen(
        onStartWorkout: _openWorkout,
      ),
      const HistoryScreen(),
      const StatsScreen(),
    ];
  }

  Future<void> _openWorkout() async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const WorkoutLoopScreen();
        },
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration:
            const Duration(milliseconds: 280),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _selectScreen(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppBottomNavigation(
          selectedIndex: selectedIndex,
          onSelected: _selectScreen,
        ),
      ),
    );
  }
}