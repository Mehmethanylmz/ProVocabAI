import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'home_screen.dart';
import 'test_menu_screen.dart';
import 'settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          child: SettingsScreen(isFirstLaunch: true),
        ),
      );
    }
  }

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
