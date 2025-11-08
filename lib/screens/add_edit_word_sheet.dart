// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\add_edit_word_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_model.dart';
import '../providers/word_provider.dart';

class AddEditWordSheet extends StatefulWidget {
  final Word? wordToEdit;
  const AddEditWordSheet({super.key, this.wordToEdit});

  @override
  State<AddEditWordSheet> createState() => _AddEditWordSheetState();
}

class _AddEditWordSheetState extends State<AddEditWordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _enController = TextEditingController();
  final _trController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TextEditingController> _sentenceControllers = [];
  final ScrollController _scrollController = ScrollController();

  bool get _isEditing => widget.wordToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final word = widget.wordToEdit!;
      _enController.text = word.en;
      _trController.text = word.tr;
      _notesController.text = word.notes;
      if (word.exampleSentences.isNotEmpty) {
        for (var sentence in word.exampleSentences) {
          _sentenceControllers.add(TextEditingController(text: sentence));
        }
      } else {
        _sentenceControllers.add(TextEditingController());
      }
    } else {
      _sentenceControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _enController.dispose();
    _trController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    for (var controller in _sentenceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSentenceField() {
    setState(() {
      _sentenceControllers.add(TextEditingController());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeSentenceField(int index) {
    if (_sentenceControllers.length > 1) {
      setState(() {
        _sentenceControllers[index].dispose();
        _sentenceControllers.removeAt(index);
      });
    } else {
      setState(() {
        _sentenceControllers[index].clear();
      });
    }
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      final List<String> sentences = _sentenceControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final newWord = Word(
        id: _isEditing
            ? widget.wordToEdit!.id
            : DateTime.now().millisecondsSinceEpoch,
        en: _enController.text.trim(),
        tr: _trController.text.trim(),
        exampleSentences: sentences,
        notes: _notesController.text.trim(),
        meaning: '',
        masteryLevel: _isEditing ? widget.wordToEdit!.masteryLevel : 0,
        reviewDueDate: _isEditing ? widget.wordToEdit!.reviewDueDate : 0,
        wrongStreak: _isEditing ? widget.wordToEdit!.wrongStreak : 0,
        status: _isEditing ? widget.wordToEdit!.status : 'unseen',
        batchId: _isEditing ? widget.wordToEdit!.batchId : null,
      );

      await Provider.of<WordProvider>(
        context,
        listen: false,
      ).addOrUpdateWord(newWord);

      if (context.mounted) {
        final action = _isEditing ? 'güncellendi' : 'eklendi';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${newWord.en}" $action!')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Kelimeyi Düzenle' : 'Yeni Kelime Ekle',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _enController,
                      decoration: InputDecoration(
                        labelText: 'İngilizce Kelime',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen İngilizce kelimeyi girin.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _trController,
                      decoration: InputDecoration(
                        labelText: 'Türkçe Karşılığı',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lütfen Türkçe karşılığını girin.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Text(
                      'Örnek Cümleler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    ..._buildSentenceFields(),
                    TextButton.icon(
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Yeni Cümle Ekle'),
                      onPressed: _addSentenceField,
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Kişisel Notlar',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _saveWord,
              child: Text(_isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSentenceFields() {
    return List.generate(_sentenceControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sentenceControllers[index],
                decoration: InputDecoration(
                  labelText: 'Örnek Cümle ${index + 1}',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeSentenceField(index),
            ),
          ],
        ),
      );
    });
  }
}
