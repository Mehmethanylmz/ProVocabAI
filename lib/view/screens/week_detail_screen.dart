import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../viewmodel/home_viewmodel.dart';

class WeekDetailScreen extends StatefulWidget {
  final String weekOfYear;
  final String year;
  final String title;

  const WeekDetailScreen({
    super.key,
    required this.weekOfYear,
    required this.year,
    required this.title,
  });

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  late Future<List<Map<String, dynamic>>> _dailyStatsFuture;

  @override
  void initState() {
    super.initState();
    _dailyStatsFuture = context.read<HomeViewModel>().getDailyStats(
      widget.weekOfYear,
      widget.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dailyStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Veriler yüklenemedi: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Bu hafta için veri bulunamadı.'));
          }

          final dailyData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: dailyData.length,
            itemBuilder: (context, index) {
              final data = dailyData[index];
              final int total = data['total'] as int;
              final int correct = data['correct'] as int;
              final int wrong = total - correct;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      data['dayName'].substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  title: Text(
                    data['dayName'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['fullDate'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    "S: $total D: $correct Y: $wrong",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
