import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../domain/entities/word_entity.dart';
import '../view_model/study_view_model.dart';
import 'test_result_view.dart';

class ListeningView extends StatefulWidget {
  const ListeningView({super.key});

  @override
  State<ListeningView> createState() => _ListeningViewState();
}

class _ListeningViewState extends State<ListeningView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAnswered = false;
  bool _isCorrect = false;
  WordEntity? _currentWord;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextWord());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    final viewModel = context.read<StudyViewModel>();
    if (viewModel.reviewQueue.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const TestResultView()));
      return;
    }
    final word = viewModel.currentReviewWord;
    setState(() {
      _currentWord = word;
      _isAnswered = false;
      _isCorrect = false;
      _controller.clear();
    });
    _focusNode.requestFocus();
    viewModel.speakCurrentWord();
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    final viewModel = context.read<StudyViewModel>();
    final isCorrect = viewModel.checkTextAnswer(_controller.text.trim());
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });
    if (isCorrect) {
      viewModel.answerCorrectly(_currentWord!);
    } else {
      viewModel.answerIncorrectly(_currentWord!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyViewModel>(
      builder: (context, viewModel, _) {
        if (_currentWord == null) {
          return Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                      color: context.colors.primary)));
        }

        final word = _currentWord!;
        final progress = viewModel.totalWordsInReview > 0
            ? (viewModel.totalWordsInReview - viewModel.reviewQueue.length) /
                viewModel.totalWordsInReview
            : 0.0;
        final targetContent = word.getLocalizedContent(viewModel.targetLang);

        return Scaffold(
          appBar: AppBar(
            title: Text('listening_test'.tr()),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: LinearProgressIndicator(
                  value: progress,
                  color: context.colors.primary,
                  backgroundColor: context.colors.outlineVariant),
            ),
          ),
          body: Padding(
            padding: context.responsive.paddingPage,
            child: Column(
              children: [
                SizedBox(height: context.responsive.spacingXL),
                GestureDetector(
                  onTap: () => viewModel.speakCurrentWord(),
                  child: Container(
                    padding: EdgeInsets.all(context.responsive.spacingXL),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volume_up_rounded,
                        size: 64, color: context.colors.primary),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(end: 1.05, duration: 1000.ms),
                SizedBox(height: context.responsive.spacingXL),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  enabled: !_isAnswered,
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'write_here'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onSubmitted: (_) => _checkAnswer(),
                ),
                if (_isAnswered) ...[
                  SizedBox(height: context.responsive.spacingL),
                  Container(
                    padding: EdgeInsets.all(context.responsive.spacingM),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? context.ext.success.withOpacity(0.1)
                          : context.colors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isCorrect ? 'correct'.tr() : 'wrong'.tr(),
                          style: TextStyle(
                              color: _isCorrect
                                  ? context.ext.success
                                  : context.colors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        if (!_isCorrect)
                          Text('correct_answer'
                              .tr(args: [targetContent['word'] ?? ''])),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isAnswered ? _loadNextWord : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswered
                          ? (_isCorrect
                              ? context.ext.success
                              : context.colors.error)
                          : context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                    ),
                    child: Text(
                        _isAnswered ? 'continue'.tr() : 'check_answer'.tr()),
                  ),
                ),
                SizedBox(height: context.responsive.spacingM),
              ],
            ),
          ),
        );
      },
    );
  }
}
