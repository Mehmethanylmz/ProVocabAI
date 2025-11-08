// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\my_words_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';
import 'add_edit_word_sheet.dart';

class MyWordsScreen extends StatefulWidget {
  const MyWordsScreen({super.key});

  @override
  State<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Provider.of<WordProvider>(context, listen: false).fetchUserWords();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditSheet(BuildContext context, Word? wordToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddEditWordSheet(wordToEdit: wordToEdit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kelimelerim')),
      body: Consumer<WordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userWords.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          final filteredWords = provider.userWords.where((word) {
            final en = word.en.toLowerCase();
            final tr = word.tr.toLowerCase();
            final query = _query.toLowerCase();
            return en.contains(query) || tr.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Kelime ara (İngilizce veya Türkçe)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (filteredWords.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _query.isEmpty
                          ? 'Henüz eklediğiniz kelime yok.\nSağ alttaki (+) butonuyla ekleyin.'
                          : 'Arama sonucu kelime bulunamadı.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      return Dismissible(
                        key: ValueKey(word.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          provider.deleteWord(word.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${word.en}" silindi.')),
                          );
                        },
                        child: ListTile(
                          title: Text(
                            word.en,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(word.tr),
                          trailing: Icon(Icons.edit_note, color: Colors.grey),
                          onTap: () => _showAddEditSheet(context, word),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddEditSheet(context, null),
        tooltip: 'Yeni Kelime Ekle',
      ),
    );
  }
}
