import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/word_provider.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const SettingsScreen({super.key, this.isFirstLaunch = false});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _currentBatchSize;

  @override
  void initState() {
    super.initState();
    _currentBatchSize = Provider.of<WordProvider>(
      context,
      listen: false,
    ).batchSize;
  }

  Future<void> _saveSettings(BuildContext context) async {
    await Provider.of<WordProvider>(
      context,
      listen: false,
    ).updateBatchSize(_currentBatchSize);

    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLaunchDone', false);
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstLaunch ? 'Hoş Geldin!' : 'Ayarlar'),
        centerTitle: true,
        automaticallyImplyLeading: !widget.isFirstLaunch,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Günde kaç kelime öğrenmek istersin?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Text(
              _currentBatchSize.toString(),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            Slider(
              value: _currentBatchSize.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              label: _currentBatchSize.toString(),
              activeColor: Theme.of(context).primaryColor,
              onChanged: (double value) {
                setState(() {
                  _currentBatchSize = value.toInt();
                });
              },
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                widget.isFirstLaunch ? 'Kaydet ve Başla' : 'Kaydet',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                _saveSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
