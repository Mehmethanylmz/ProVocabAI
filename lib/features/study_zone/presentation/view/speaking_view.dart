import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../view_model/study_view_model.dart';
import '../../domain/entities/word_entity.dart';
import 'test_result_view.dart';

class SpeakingView extends StatefulWidget {
  const SpeakingView({super.key});

  @override
  State<SpeakingView> createState() => _SpeakingViewState();
}

class _SpeakingViewState extends State<SpeakingView> {
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _hasPermission = false;
  WordEntity? _currentWord;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextWord());
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _loadNextWord() async {
    final viewModel = locator<StudyViewModel>();
    if (viewModel.reviewQueue.isEmpty) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const TestResultView()));
      return;
    }
    setState(() {
      _currentWord = viewModel.currentReviewWord;
      _isAnswered = false;
      _isCorrect = false;
    });
  }

  void _handleMicPress(bool isDown) async {
    if (_isAnswered || !_hasPermission) return;
    final viewModel = locator<StudyViewModel>();
    if (isDown) {
      await viewModel.startListeningForSpeech();
    } else {
      await viewModel.stopListeningForSpeech();
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final viewModel = locator<StudyViewModel>();
    if (viewModel.spokenText.isEmpty) return;

    final isCorrect = viewModel.checkTextAnswer(viewModel.spokenText);
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
    return BaseView<StudyViewModel>(
      viewModel: locator<StudyViewModel>(),
      onModelReady: (_) {},
      builder: (context, viewModel, child) {
        if (_currentWord == null) {
          return Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                      color: context.colors.primary)));
        }

        final word = _currentWord!;
        final content = word.getLocalizedContent(viewModel.targetLang);

        return Scaffold(
          appBar: AppBar(title: Text('speaking_test'.tr())),
          body: Padding(
            padding: context.responsive.paddingPage,
            child: Column(
              children: [
                SizedBox(height: context.responsive.spacingXL),
                Text(
                  content['word'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: context.responsive.spacingM),
                IconButton(
                  onPressed: () => viewModel.speakText(
                      content['word']!, viewModel.targetLang),
                  icon: Icon(Icons.volume_up,
                      size: 32, color: context.colors.primary),
                ),
                Spacer(),
                if (viewModel.spokenText.isNotEmpty)
                  Text("“${viewModel.spokenText}”",
                      style:
                          TextStyle(fontSize: 20, fontStyle: FontStyle.italic)),
                SizedBox(height: context.responsive.spacingL),
                if (_isAnswered)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: _isCorrect
                        ? context.ext.success.withOpacity(0.2)
                        : context.colors.error.withOpacity(0.2),
                    child: Text(_isCorrect ? "Perfect!" : "Try Again"),
                  ),
                SizedBox(height: context.responsive.spacingL),
                if (!_isAnswered)
                  GestureDetector(
                    onLongPressStart: (_) => _handleMicPress(true),
                    onLongPressEnd: (_) => _handleMicPress(false),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: viewModel.isListening
                            ? context.colors.error
                            : context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mic, color: Colors.white, size: 40),
                    ),
                  ),
                if (_isAnswered)
                  ElevatedButton(
                    onPressed: _loadNextWord,
                    child: Text('continue'.tr()),
                  ),
                SizedBox(height: context.responsive.spacingXL),
              ],
            ),
          ),
        );
      },
    );
  }
}
