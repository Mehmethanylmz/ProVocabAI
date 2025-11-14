import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SettingsScreen({super.key, this.isFirstLaunch = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _currentBatchSize;
  late bool _currentAutoPlaySound;
  bool _isInitialized = false;

  Future<void> _saveSettings(BuildContext context) async {
    final viewModel = context.read<SettingsViewModel>();

    await viewModel.updateBatchSize(_currentBatchSize);
    await viewModel.updateAutoPlaySound(_currentAutoPlaySound);

    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
    }

    if (!mounted) return;
    context.read<HomeViewModel>().loadHomeData();
    context.read<TestMenuViewModel>().loadTestData();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;

    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!_isInitialized) {
          _currentBatchSize = viewModel.batchSize;
          _currentAutoPlaySound = viewModel.autoPlaySound;
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isFirstLaunch ? 'Hoş Geldin!' : 'Ayarlar',
              style: TextStyle(fontSize: titleFontSize),
            ),
            centerTitle: true,
            automaticallyImplyLeading: !widget.isFirstLaunch,
            backgroundColor: Colors.blue[700],
          ),
          body: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'Günde kaç kelime öğrenmek istersin?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: isSmallScreen ? 18 : 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  _currentBatchSize.toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: isSmallScreen ? 32 : 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Slider(
                  value: _currentBatchSize.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: _currentBatchSize.toString(),
                  activeColor: Colors.green[600],
                  onChanged: (double value) {
                    setState(() {
                      _currentBatchSize = value.toInt();
                    });
                  },
                ),
                Divider(height: 40, color: Colors.grey[300]),
                SwitchListTile(
                  title: Text(
                    'Otomatik Sesli Okuma',
                    style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
                  ),
                  subtitle: Text(
                    'Yeni kelime göründüğünde otomatik oynat.',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                  secondary: Icon(
                    Icons.record_voice_over,
                    size: isSmallScreen ? 32 : 40,
                    color: Colors.blue[700],
                  ),
                  value: _currentAutoPlaySound,
                  activeColor: Colors.green[600],
                  onChanged: (bool value) {
                    setState(() {
                      _currentAutoPlaySound = value;
                    });
                  },
                ),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 40 : 60,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.isFirstLaunch ? 'Kaydet ve Başla' : 'Kaydet',
                    style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
                  ),
                  onPressed: () {
                    _saveSettings(context);
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
