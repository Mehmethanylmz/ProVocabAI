import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../widgets/home/skill_radar_card.dart';
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

  void _shareProgress(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();
    final stats = viewModel.stats;
    final tiers = stats?.tierDistribution ?? {};

    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstatistikler yüklenemedi.')));
      return;
    }

    final String progressText = """
🚀 Kelime Uygulaması İlerlemem! 🚀

📊 **Genel İstatistikler**
- **Ustalaşılan Kelime:** ${stats.masteredWords}
- **Bu Hafta Çözülen:** ${stats.weekQuestions} Soru
- **Haftalık Başarı:** ${stats.weekSuccessRate.toStringAsFixed(0)}%

🧠 **Kelime Seviyelerim**
- **Uzman:** ${tiers['Expert'] ?? 0}
- **Çırak:** ${tiers['Apprentice'] ?? 0}
- **Acemi:** ${tiers['Novice'] ?? 0}
""";

    Share.share(progressText, subject: 'Kelime İlerlemem');
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
          'Art arda hata yaptığın $difficultWordCount kelime var. Bunları "Test Alanı"ndan tekrar edebilirsin.',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'dashboard_title'.tr(), // "İlerleme"
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              pinned: true,
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareProgress(context),
                ),
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
                  // --- YENİ EKLENEN KISIM: YETENEK RADARI ---
                  Text(
                    'skill_analysis_title'.tr(), // "Yetenek Analizi"
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ).animate().fadeIn(),

                  SkillRadarCard(
                    skills: viewModel.skillStats,
                    messageKey: viewModel.coachMessage,
                  ),

                  const SizedBox(height: 24),

                  // --- ESKİ KISIMLAR (AYNEN DURUYOR) ---
                  Text(
                    'İstatistiklerin', // 'stats_title'.tr()
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

                  const ActivityHistoryList(),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
