import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import '../../viewmodel/main_viewmodel.dart';
import 'settings_screen.dart';
import '../widgets/home/skill_radar_card.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
    final shareText = viewModel.generateShareProgressText();

    if (shareText != null) {
      Share.share(shareText, subject: 'Kelime İlerlemem');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İstatistikler yüklenemedi.'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showDifficultWordsDialog(int difficultWordCount) {
    if (!mounted) return;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Zor Kelimeler Tespit Edildi',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Art arda hata yaptığın $difficultWordCount kelime var. Bunları "Test Alanı"ndan tekrar edebilirsin.',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            height: 1.5,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                elevation: 5,
              ),
              child: Text(
                'Anladım',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- APP BAR ---
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: const Color(0xFFF8F9FD),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'dashboard_title'.tr(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.share_rounded, color: Colors.blue[700]),
                  onPressed: () => _shareProgress(context),
                  tooltip: 'Paylaş',
                ),
              ),
              // Ayarlar Butonu
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.settings_rounded, color: Colors.purple[700]),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  tooltip: 'Ayarlar',
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildSectionHeader(
                  'AI Koç Analizi',
                  'Beceri ve çalışma hacmi analizi',
                  const [Color(0xFF667eea), Color(0xFF764ba2)],
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                SkillRadarCard(
                  volumeStats: viewModel.volumeStats,
                  accuracyStats: viewModel.accuracyStats,
                  message: viewModel.coachMessage,
                ),

                const SizedBox(height: 32),

                _buildSectionHeader(
                  'Hızlı İstatistikler',
                  'Günlük, haftalık ve aylık performansın',
                  const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                DashboardStatsGrid(
                  stats: viewModel.stats,
                ),

                const SizedBox(height: 32),

                _buildSectionHeader(
                  'Kelime Seviyeleri',
                  'Kelimelerinin seviye dağılımı',
                  const [Color(0xFF11998e), Color(0xFF38ef7d)],
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                WordTierPanel(
                  tierDistribution: viewModel.stats?.tierDistribution ?? {},
                ),

                const SizedBox(height: 32),

                // 4. Detaylı Geçmiş
                _buildSectionHeader(
                  'Detaylı Analiz',
                  'Aylık ve haftalık aktivite geçmişin',
                  const [Color(0xFFF093FB), Color(0xFFF5576C)],
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                const ActivityHistoryList(),

                const SizedBox(height: 100), // Alt kısımda boşluk (FAB için)
              ]),
            ),
          ),
        ],
      ),

      // --- GÜNCELLENMİŞ HIZLI BAŞLA BUTONU ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 1. Test verilerini arka planda tazeleyelim ki hazır olsun
          context.read<TestMenuViewModel>().loadTestData();

          // 2. MainViewModel aracılığıyla sekmeyi "1" (Test Sekmesi) yapalım.
          // Bu işlem anında Test Ekranını açar.
          context.read<MainViewModel>().changeTab(1);
        },
        backgroundColor: Colors.blue[600],
        elevation: 6,
        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
        label: Text(
          'Hızlı Başla',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: false))
          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
    );
  }

  // Bölüm Başlığı Yardımcı Widget'ı
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    List<Color> gradientColors,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
