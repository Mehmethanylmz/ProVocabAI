import 'package:flutter/material.dart';

enum TestType { writing, multipleChoice }

Future<TestType?> showTestTypeDialog(BuildContext context) async {
  return await showDialog<TestType>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Test Türünü Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Yazarak Test'),
              subtitle: Text('Kelimenin karşılığını yazarsın.'),
              onTap: () {
                Navigator.of(context).pop(TestType.writing);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Çoktan Seçmeli'),
              subtitle: Text('4 şık arasından doğruyu seçersin.'),
              onTap: () {
                Navigator.of(context).pop(TestType.multipleChoice);
              },
            ),
          ],
        ),
      );
    },
  );
}
