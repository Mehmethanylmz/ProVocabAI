import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/word_provider.dart';
import 'services/database_helper.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.populateDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WordProvider(),
      child: MaterialApp(
        title: 'Kelime Ezberle',
        theme: ThemeData(
          primaryColor: Color(0xFF4A90E2),
          scaffoldBackgroundColor: Color(0xFFF4F6F8),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF50E3C2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
  }
}
