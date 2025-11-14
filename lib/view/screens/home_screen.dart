import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'settings_screen.dart';
import '../widgets/home/dashboard_stats_grid.dart';
import '../widgets/home/word_tier_panel.dart';
import '../widgets/home/activity_history_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _difficultWordsPopupShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.difficultWords.length > 2 && !_difficultWordsPopupShown) {
      _difficultWordsPopupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDifficultWordsDialog(viewModel.difficultWords.length);
        }
      });
    }
  }

  void _showDifficultWordsDialog(int difficultWordCount) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Zor Kelimeler Tespit Edildi',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Art arda hata yaptığın $difficultWordCount kelime var. Bunları şimdi "Test Et" sekmesinden tekrar edebilirsin.',
          style: TextStyle(fontSize: isSmallScreen ? 14 : 18),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                'Tamam',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'İlerleme',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              pinned: true,
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'İstatistiklerin',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  SizedBox(height: size.height * 0.02),
                  DashboardStatsGrid(
                    stats: viewModel.stats,
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    'Kelime Seviyeleri',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  WordTierPanel(
                    tierDistribution: viewModel.stats?.tierDistribution ?? {},
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    'Detaylı Analiz',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  SizedBox(height: size.height * 0.02),
                  ActivityHistoryList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
