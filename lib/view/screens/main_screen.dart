import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import '../../viewmodel/main_viewmodel.dart';
import 'home_screen.dart';
import 'test_menu_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const TestMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final mainViewModel = context.watch<MainViewModel>();

    return Scaffold(
      // extendBody: true sayesinde içerik bottom bar'ın arkasına kadar uzanır.
      // Bu, barın "havada asılı" gibi görünmesini sağlar.
      extendBody: true,
      body: IndexedStack(
        index: mainViewModel.selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _ModernBottomNav(
        selectedIndex: mainViewModel.selectedIndex,
        onTap: (index) {
          // Sekmeyi değiştir
          context.read<MainViewModel>().changeTab(index);

          // Verileri tazele
          if (index == 0) {
            context.read<HomeViewModel>().loadHomeData();
          } else if (index == 1) {
            context.read<TestMenuViewModel>().loadTestData();
          }
        },
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _ModernBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Container(
      // Barın kenarlardan ne kadar içeride olacağı
      margin: EdgeInsets.fromLTRB(isSmallScreen ? 20 : 32, 0,
          isSmallScreen ? 20 : 32, isSmallScreen ? 24 : 32),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Daha yuvarlak hatlar
        boxShadow: [
          // Ana gölge (daha derinlikli)
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          // Hafif mavi parlama
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'İlerleme',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
            gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
            isSmallScreen: isSmallScreen,
          ),
          _NavItem(
            icon: Icons
                .rocket_launch_rounded, // Roket ikonu çalışma/pratik moduna da gayet uygun
            label: 'Çalışma', // <-- DEĞİŞİKLİK BURADA
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
            gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradient;
  final bool isSmallScreen;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded sayesinde butonlar tüm alanı eşit paylaşır
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint, // Daha yumuşak animasyon eğrisi
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            // Seçiliyse gradient arka plan, değilse şeffaf
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            // Seçiliyse hafif gölge verelim ki havada dursun
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                // Seçiliyse beyaz, değilse gri
                color: isSelected ? Colors.white : Colors.grey[400],
                size: isSmallScreen ? 24 : 28,
              ),
              // Animasyonlu genişleme: Sadece seçiliyse metni göster
              if (isSelected) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
