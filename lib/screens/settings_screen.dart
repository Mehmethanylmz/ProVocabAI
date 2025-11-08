// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\settings_screen.dart

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
  late TimeOfDay _currentNotificationTime;
  late bool _currentAutoPlaySound;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<WordProvider>(context, listen: false);
    _currentBatchSize = provider.batchSize;
    _currentNotificationTime = provider.notificationTime;
    _currentAutoPlaySound = provider.autoPlaySound;
  }

  Future<void> _saveSettings(BuildContext context) async {
    final provider = Provider.of<WordProvider>(context, listen: false);

    await provider.updateBatchSize(_currentBatchSize);
    await provider.updateNotificationTime(_currentNotificationTime);
    await provider.updateAutoPlaySound(_currentAutoPlaySound);

    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLaunchDone', false);
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _currentNotificationTime,
    );
    if (picked != null && picked != _currentNotificationTime) {
      setState(() {
        _currentNotificationTime = picked;
      });
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
          children: [
            SizedBox(height: 20),
            Text(
              'Günde kaç kelime öğrenmek istersin?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
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
            Divider(height: 40),
            ListTile(
              leading: Icon(Icons.notifications_active),
              title: Text('Günlük Hatırlatıcı Saati'),
              subtitle: Text('Her gün bu saatte bildirim alırsın.'),
              trailing: Text(
                _currentNotificationTime.format(context),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _selectTime(context),
            ),
            Divider(height: 20),
            SwitchListTile(
              title: Text('Otomatik Sesli Okuma'),
              subtitle: Text('Yeni kelime göründüğünde otomatik oynat.'),
              secondary: Icon(Icons.record_voice_over),
              value: _currentAutoPlaySound,
              onChanged: (bool value) {
                setState(() {
                  _currentAutoPlaySound = value;
                });
              },
            ),
            Spacer(),
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
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
