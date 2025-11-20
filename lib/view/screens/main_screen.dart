import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'home_screen.dart';
import 'test_menu_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TestMenuScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      context.read<HomeViewModel>().loadHomeData();
    } else if (index == 1) {
      context.read<TestMenuViewModel>().loadTestData();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final iconSize = isSmallScreen ? 24.0 : 32.0;
    final labelStyle = TextStyle(fontSize: isSmallScreen ? 12 : 16);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline, size: iconSize),
            activeIcon: Icon(Icons.lightbulb, size: iconSize),
            label: 'İlerleme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined, size: iconSize),
            activeIcon: Icon(Icons.quiz, size: iconSize),
            label: 'Test',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8.0,
        selectedLabelStyle: labelStyle.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: labelStyle,
      ),
    );
  }
}
