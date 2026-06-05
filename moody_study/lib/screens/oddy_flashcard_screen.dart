import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/error/exception_mapper.dart';
import 'package:moody_study/core/error/failures.dart';
import 'package:moody_study/models/generated_quiz_response.dart';
import 'package:moody_study/services/material_service.dart';

class OddyFlashcardScreen extends StatefulWidget {
  final int materialId;
  final String fileName;

  const OddyFlashcardScreen({
    super.key,
    required this.materialId,
    required this.fileName,
  });

  @override
  State<OddyFlashcardScreen> createState() => _OddyFlashcardScreenState();
}

class QuizCard {
  final String question;
  final String? answer;
  final Map<String, String>? options;
  final String? explanation;
  final String? type;
  bool revealed = false;

  QuizCard({
    required this.question,
    this.answer,
    this.options,
    this.explanation,
    this.type,
  });
}

class _OddyFlashcardScreenState extends State<OddyFlashcardScreen> {
  String _quizType = 'multiple_choice';
  int _questionCount = 5;
  bool _generating = false;
  String? _error;
  GeneratedQuizResponse? _generatedQuiz;
  List<QuizCard> _cards = [];

  Future<Either<AppFailure, GeneratedQuizResponse>> _fetchGeneratedQuiz() async {
    try {
      return Right(await MaterialService.generateQuiz(
        materialId: widget.materialId,
        quizType: _quizType,
        questionCount: _questionCount,
      ));
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }

  Future<void> _generateFlashcards() async {
    setState(() { _generating = true; _error = null; _generatedQuiz = null; _cards = []; });

    final result = await _fetchGeneratedQuiz();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.localizedMessage(context); _generating = false; }),
      (quiz) {
        final cards = _parseQuizContent(quiz.quizContent);
        setState(() { _generatedQuiz = quiz; _cards = cards; _generating = false; });
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardResultScreen(
                fileName: quiz.fileName,
                cards: cards,
                quizId: quiz.id,
              ),
            ),
          );
        }
      },
    );
  }

  List<QuizCard> _parseQuizContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];

    final normalized = _normalizeQuizContent(trimmed);
    final decoded = _decodePotentialJson(normalized);

    if (decoded is List) {
      final cards = <QuizCard>[];
      for (final item in decoded) {
        final card = _tryParseQuizItem(item);
        if (card != null) cards.add(card);
      }
      if (cards.isNotEmpty) return cards;
    } else if (decoded is Map<String, dynamic>) {
      final cards = <QuizCard>[];
      if (decoded['questions'] is List) {
        for (final item in decoded['questions'] as List) {
          final card = _tryParseQuizItem(item);
          if (card != null) cards.add(card);
        }
      } else if (decoded['cards'] is List) {
        for (final item in decoded['cards'] as List) {
          final card = _tryParseQuizItem(item);
          if (card != null) cards.add(card);
        }
      } else if (decoded['data'] is List) {
        for (final item in decoded['data'] as List) {
          final card = _tryParseQuizItem(item);
          if (card != null) cards.add(card);
        }
      } else if (decoded.containsKey('question')) {
        final card = _tryParseQuizItem(decoded);
        if (card != null) cards.add(card);
      } else if (decoded['quizContent'] is String) {
        return _parseQuizContent(decoded['quizContent'] as String);
      }
      if (cards.isNotEmpty) return cards;
    }

    final blocks = normalized
        .split(RegExp(r'\n{2,}'))
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (blocks.isEmpty) {
      return [QuizCard(question: normalized, answer: null)];
    }

    final cards = <QuizCard>[];
    for (final block in blocks) {
      final parsed = _extractQuestionAnswerFromRaw(block);
      if (parsed != null) {
        cards.add(parsed);
        continue;
      }

      final normalizedBlock = block.trim();
      final answerIndex = normalizedBlock.toLowerCase().indexOf('answer:');
      if (answerIndex >= 0) {
        final questionPart = normalizedBlock.substring(0, answerIndex).trim();
        final answerPart = normalizedBlock.substring(answerIndex + 7).trim();
        cards.add(QuizCard(question: questionPart, answer: answerPart));
      } else {
        cards.add(QuizCard(question: normalizedBlock, answer: null));
      }
    }

    return cards;
  }

  String _normalizeQuizContent(String content) {
    var normalized = content.trim();

    final codeFence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final match = codeFence.firstMatch(normalized);
    if (match != null && match.groupCount >= 1) {
      normalized = match.group(1)!.trim();
    }

    if (normalized.toLowerCase().startsWith('json')) {
      normalized = normalized.substring(4).trim();
    }

    return normalized;
  }

  Either<AppFailure, dynamic> _tryDecodeJson(String value) {
    try {
      return Right(jsonDecode(value));
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }

  dynamic _decodePotentialJson(String value) {
    var current = value.trim();
    for (var i = 0; i < 4; i++) {
      final result = _tryDecodeJson(current);
      if (result.isLeft()) {
        if ((current.startsWith('"') && current.endsWith('"')) ||
            (current.startsWith("'") && current.endsWith("'"))) {
          current = current.substring(1, current.length - 1).trim();
          continue;
        }
        break;
      }
      final decoded = result.getOrElse(() => current);
      if (decoded is String) {
        current = decoded.trim();
        continue;
      }
      return decoded;
    }

    final jsonMatch = RegExp(r'([\[{].*[\]}])', dotAll: true).firstMatch(current);
    if (jsonMatch != null) {
      final result = _tryDecodeJson(jsonMatch.group(1)!);
      if (result.isRight()) return result.getOrElse(() => current);
    }

    return current;
  }

  QuizCard? _tryParseQuizItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      final questionValue = item['question'] ?? item['text'] ?? item['prompt'] ?? item['questionText'] ?? item['content'];
      var question = questionValue?.toString().trim() ?? '';
      if (question.isEmpty) {
        question = _extractQuestionAnswerFromRaw(item.toString())?.question ?? '';
      }
      final answer = item['answer']?.toString();
      final explanation = item['explanation']?.toString();
      final type = item['type']?.toString();
      Map<String, String>? options;
      if (item['options'] is Map) {
        options = (item['options'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      if (question.isEmpty && answer == null) return null;
      return QuizCard(
        question: question.isNotEmpty ? question : 'Question unavailable',
        answer: answer,
        explanation: explanation,
        options: options,
        type: type,
      );
    }

    if (item is String) {
      final decoded = _decodePotentialJson(item);
      if (decoded is Map<String, dynamic>) return _tryParseQuizItem(decoded);
      if (decoded is List && decoded.isNotEmpty) return _tryParseQuizItem(decoded.first);
      return _extractQuestionAnswerFromRaw(item);
    }

    return null;
  }

  QuizCard? _extractQuestionAnswerFromRaw(String raw) {
    final questionMatch = RegExp(r'"question"\s*:\s*"(.+?)"', dotAll: true).firstMatch(raw);
    final answerMatch = RegExp(r'"answer"\s*:\s*"(.+?)"', dotAll: true).firstMatch(raw);
    if (questionMatch != null) {
      return QuizCard(
        question: questionMatch.group(1)!.trim(),
        answer: answerMatch?.group(1)?.trim(),
      );
    }
    final fallbackQuestion = RegExp(r'question\s*[:\-]\s*(.+?)(?:\n|\r|$)', caseSensitive: false).firstMatch(raw)?.group(1)?.trim();
    final fallbackAnswer = RegExp(r'answer\s*[:\-]\s*(.+?)(?:\n|\r|$)', caseSensitive: false).firstMatch(raw)?.group(1)?.trim();
    if (fallbackQuestion != null) {
      return QuizCard(question: fallbackQuestion, answer: fallbackAnswer);
    }
    return null;
  }

  // fall back string is now English
  String _getUnknownQuestionText() => 'Question unavailable';

  Widget _buildQuizTypeButton(String value, String label) {
    final selected = _quizType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _quizType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3AA9E8) : Colors.white,
            border: Border.all(color: const Color(0xFF111111), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF111111),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: const Text(
          'Oddy\'s Flashcards',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the quiz type based on the material you uploaded. Oddy will create questions from that material.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildQuizTypeButton(
                          'multiple_choice',
                          'Multiple Choice',
                        ),
                        const SizedBox(width: 12),
                        _buildQuizTypeButton('essay', 'Short Answer'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Number of questions',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text('$_questionCount'),
                      ],
                    ),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_questionCount',
                      onChanged: (value) {
                        setState(() {
                          _questionCount = value.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _generating ? null : _generateFlashcards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _generating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Flashcards'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDD2222)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFF990000)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: Center(
                  child: Text(
                    'Press Create Flashcards to generate questions from the material you uploaded.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardResultScreen extends StatefulWidget {
  final String fileName;
  final List<QuizCard> cards;
  final int quizId;
  final bool isSaved;

  const FlashcardResultScreen({
    super.key,
    required this.fileName,
    required this.cards,
    required this.quizId,
    this.isSaved = false,
  });

  @override
  State<FlashcardResultScreen> createState() => _FlashcardResultScreenState();
}

class _FlashcardResultScreenState extends State<FlashcardResultScreen> {
  late bool _isSaved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  Future<Either<AppFailure, bool>> _doToggleSave() async {
    try {
      final result = await MaterialService.toggleSaveQuiz(widget.quizId);
      return Right(result.saved);
    } catch (e) {
      return Left(ExceptionMapper.map(e));
    }
  }

  Future<void> _toggleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await _doToggleSave();
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(f.localizedMessage(context)),
          backgroundColor: const Color(0xFFEF5350),
        ));
      },
      (saved) {
        setState(() { _isSaved = saved; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSaved ? '✅ Flashcard disimpan ke tab Kuis!' : 'Flashcard dihapus dari tab Kuis'),
          backgroundColor: _isSaved ? const Color(0xFF1EE86F) : const Color(0xFF555555),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: Text(
          'Questions from: ${widget.fileName}',
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: const Color(0xFFF2EA05),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: widget.cards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 52,
                                color: Color(0xFF888888),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No quiz cards are available yet. If you saved a quiz from another screen, it may contain content that needs to be parsed first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: widget.cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final card = widget.cards[index];
                          return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Flashcard ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (card.answer != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      card.revealed = !card.revealed;
                                    });
                                  },
                                  child: Text(
                                    card.revealed
                                        ? 'Hide Answer'
                                        : 'Show Answer',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card.question,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (card.options != null && card.options!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...card.options!.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key}. ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (card.answer != null && card.revealed) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFCCCCCC)),
                            const SizedBox(height: 12),
                            Text(
                              'Answer: ${card.answer!}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Explanation: ${card.explanation!}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _toggleSave,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(
                    _isSaved ? 'Saved to Quiz' : 'Save to Quiz',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved ? const Color(0xFF1EE86F) : const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}