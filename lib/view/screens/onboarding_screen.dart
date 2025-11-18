import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodel/onboarding_viewmodel.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: viewModel.currentPage,
                  children: [
                    _buildLanguageSelection(
                      context,
                      'Hangi dili konuşuyorsun?',
                      'Ana Dilin',
                      viewModel.selectedSourceLang,
                      viewModel.languages,
                      (val) => viewModel.setSourceLang(val),
                    ),
                    _buildLanguageSelection(
                      context,
                      'Hangi dili öğrenmek istiyorsun?',
                      'Hedef Dil',
                      viewModel.selectedTargetLang,
                      viewModel.languages,
                      (val) => viewModel.setTargetLang(val),
                      exclude: viewModel.selectedSourceLang,
                    ),
                    _buildLevelSelection(context, viewModel),
                  ],
                ),
              ),
              _buildBottomBar(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelection(
    BuildContext context,
    String title,
    String subtitle,
    String selectedValue,
    Map<String, String> options,
    Function(String) onSelect, {
    String? exclude,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 32),
        Expanded(
          child: ListView(
            children: options.entries.map((entry) {
              if (entry.key == exclude) return SizedBox.shrink();

              final isSelected = entry.key == selectedValue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () => onSelect(entry.key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getFlag(entry.key),
                          style: TextStyle(fontSize: 32),
                        ),
                        SizedBox(width: 16),
                        Text(
                          entry.value,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.blue[900]
                                : Colors.black87,
                          ),
                        ),
                        Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelection(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40),
        Text(
          'Seviyen nedir?',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Bu seçim, örnek cümlelerin zorluk derecesini belirler.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 32),
        Expanded(
          child: ListView(
            children: viewModel.levels.entries.map((entry) {
              final isSelected = entry.key == viewModel.selectedLevel;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () => viewModel.setLevel(entry.key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.value,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue[900]
                                    : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 28,
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getLevelDescription(entry.key),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OnboardingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (viewModel.currentPage > 0)
            TextButton(
              onPressed: viewModel.previousPage,
              child: Text(
                'Geri',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox.shrink(),

          ElevatedButton(
            onPressed: () async {
              if (viewModel.currentPage < 2) {
                viewModel.nextPage();
              } else {
                await viewModel.completeOnboarding();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              viewModel.currentPage == 2 ? 'Başla' : 'İleri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFlag(String langCode) {
    switch (langCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'pt':
        return '🇵🇹';
      default:
        return '🏳️';
    }
  }

  String _getLevelDescription(String level) {
    switch (level) {
      case 'beginner':
        return 'Temel kelimeler ve basit cümleler.';
      case 'intermediate':
        return 'Daha karmaşık gramer ve günlük konuşmalar.';
      case 'advanced':
        return 'Akademik veya profesyonel düzeyde ifadeler.';
      default:
        return '';
    }
  }
}
