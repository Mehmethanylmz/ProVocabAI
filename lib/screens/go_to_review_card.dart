import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'review_screen.dart';
import 'review_screen_multiple_choice.dart';
import 'test_type_dialog.dart';

class GoToReviewCard extends StatelessWidget {
  const GoToReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text('Harika!', style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 10),
            Text(
              'Tüm kelimeleri gözden geçirdin. Şimdi kendini test etmeye hazır mısın?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () async {
                final provider = Provider.of<WordProvider>(
                  context,
                  listen: false,
                );

                final TestType? testType = await showTestTypeDialog(context);

                if (testType == null || !context.mounted) return;

                await provider.startReview(testMode: 'current');

                if (!context.mounted) return;

                if (testType == TestType.writing) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReviewScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewScreenMultipleChoice(),
                    ),
                  );
                }
              },
              child: Text(
                'Testi Başlat',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
