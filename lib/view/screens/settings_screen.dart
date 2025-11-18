import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SettingsScreen({super.key, this.isFirstLaunch = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _currentBatchSize;
  late bool _currentAutoPlaySound;
  late String _currentSourceLang;
  late String _currentTargetLang;
  late String _currentProficiencyLevel;

  bool _isInitialized = false;

  final Map<String, String> languages = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
  };

  final Map<String, String> levels = {
    'beginner': 'Başlangıç (A1-A2)',
    'intermediate': 'Orta (B1-B2)',
    'advanced': 'İleri (C1-C2)',
  };

  Future<void> _saveSettings(BuildContext context) async {
    final viewModel = context.read<SettingsViewModel>();

    await viewModel.updateBatchSize(_currentBatchSize);
    await viewModel.updateAutoPlaySound(_currentAutoPlaySound);
    await viewModel.updateLanguages(_currentSourceLang, _currentTargetLang);
    await viewModel.updateLevel(_currentProficiencyLevel);

    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch_v2', false);
    }

    if (!mounted) return;

    context.read<HomeViewModel>().loadHomeData();
    context.read<TestMenuViewModel>().loadTestData();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!_isInitialized) {
          _currentBatchSize = viewModel.batchSize;
          _currentAutoPlaySound = viewModel.autoPlaySound;
          _currentSourceLang = viewModel.sourceLang;
          _currentTargetLang = viewModel.targetLang;
          _currentProficiencyLevel = viewModel.proficiencyLevel;
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Ayarlar'),
            centerTitle: true,
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Dil Ayarları'),

              ListTile(
                title: Text('Ana Dilin'),
                subtitle: Text(languages[_currentSourceLang] ?? ''),
                trailing: DropdownButton<String>(
                  value: _currentSourceLang,
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSourceLang = newValue;
                        if (_currentTargetLang == newValue) {
                          _currentTargetLang = newValue == 'en' ? 'tr' : 'en';
                        }
                      });
                    }
                  },
                  items: languages.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                ),
              ),

              ListTile(
                title: Text('Öğrenilen Dil'),
                subtitle: Text(languages[_currentTargetLang] ?? ''),
                trailing: DropdownButton<String>(
                  value: _currentTargetLang,
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _currentSourceLang) {
                      setState(() => _currentTargetLang = newValue);
                    }
                  },
                  items: languages.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      enabled: e.key != _currentSourceLang,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: e.key == _currentSourceLang
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              ListTile(
                title: Text('Zorluk Seviyesi'),
                subtitle: Text('Örnek cümlelerin karmaşıklığı'),
                trailing: DropdownButton<String>(
                  value: _currentProficiencyLevel,
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _currentProficiencyLevel = newValue);
                    }
                  },
                  items: levels.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                ),
              ),

              Divider(height: 30),
              _buildSectionHeader('Çalışma Ayarları'),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Günlük Kelime Hedefi: $_currentBatchSize'),
                    Slider(
                      value: _currentBatchSize.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: _currentBatchSize.toString(),
                      activeColor: Colors.blue[700],
                      onChanged: (val) =>
                          setState(() => _currentBatchSize = val.toInt()),
                    ),
                  ],
                ),
              ),

              SwitchListTile(
                title: Text('Otomatik Seslendirme'),
                value: _currentAutoPlaySound,
                activeThumbColor: Colors.blue[700],
                onChanged: (val) => setState(() => _currentAutoPlaySound = val),
              ),

              SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _saveSettings(context),
                child: Text('Kaydet', style: TextStyle(fontSize: 18)),
              ),

              if (!widget.isFirstLaunch) ...[
                SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isFirstLaunch_v2', true);
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => OnboardingScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: Text(
                    'Başlangıç Ekranına Dön (Reset)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
