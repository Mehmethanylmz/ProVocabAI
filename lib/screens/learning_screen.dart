import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'word_card_widget.dart';
import 'go_to_review_card.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  late int _totalItems;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<WordProvider>(context, listen: false);
    _totalItems = provider.currentBatch.length + 1;
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordProvider>(context, listen: false);
    final wordBatch = provider.currentBatch;

    return Scaffold(
      appBar: AppBar(title: Text('Öğrenme Ekranı')),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _totalItems,
            itemBuilder: (context, index) {
              if (index < wordBatch.length) {
                return WordCardWidget(
                  word: wordBatch[index],
                  progress: '${index + 1} / ${wordBatch.length}',
                );
              } else {
                return GoToReviewCard();
              }
            },
          ),
          _buildNavigationButtons(context, wordBatch.length),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, int wordCount) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              FloatingActionButton(
                heroTag: 'prev',
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_back),
              )
            else
              SizedBox(width: 56),
            if (_currentPage < wordCount)
              FloatingActionButton(
                heroTag: 'next',
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_forward),
              )
            else
              SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}
