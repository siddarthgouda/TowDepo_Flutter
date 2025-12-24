// lib/main_shell.dart
import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/nearby_stores_screen.dart';
import '../pages/notification_page.dart';
import '../pages/account_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // one navigator key per tab
  final List<GlobalKey<NavigatorState>> _navKeys =
  List.generate(4, (_) => GlobalKey<NavigatorState>());

  Widget _buildOffstageNavigator(int index, Widget child) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (_) => child);
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final currentNav = _navKeys[_currentIndex].currentState!;
    if (currentNav.canPop()) {
      currentNav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            _buildOffstageNavigator(0, const HomeScreen()),
            _buildOffstageNavigator(1, const AllStoresScreen()),
            _buildOffstageNavigator(2, const NotificationsScreen()),
            _buildOffstageNavigator(3, const AccountScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFFF66622),
          unselectedItemColor: Colors.grey,
            onTap: (index) {
              // ALWAYS pop to root when home tab is tapped
              if (index == 0) {
                _navKeys[0].currentState?.popUntil((route) => route.isFirst);
              }

              if (index == _currentIndex) {
                // Tapping same tab resets its stack
                _navKeys[index].currentState?.popUntil((r) => r.isFirst);
              } else {
                // Switch tabs
                setState(() => _currentIndex = index);
              }
            },
            items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_business), label: 'stores'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
