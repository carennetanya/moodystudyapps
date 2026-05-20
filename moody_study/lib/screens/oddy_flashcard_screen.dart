import 'dart:convert';

import 'package:flutter/material.dart';
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

class _QuizCard {
  final String question;
  final String? answer;
  final Map<String, String>? options;
  final String? explanation;
  final String? type;
  bool revealed = false;

  _QuizCard({
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
  List<_QuizCard> _cards = [];

  Future<void> _generateFlashcards() async {
    setState(() {
      _generating = true;
      _error = null;
      _generatedQuiz = null;
      _cards = [];
    });

    try {
      final quiz = await MaterialService.generateQuiz(
        materialId: widget.materialId,
        quizType: _quizType,
        questionCount: _questionCount,
      );

      final cards = _parseQuizContent(quiz.quizContent);
      setState(() {
        _generatedQuiz = quiz;
        _cards = cards;
      });

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FlashcardResultScreen(
              fileName: quiz.fileName,
              cards: cards,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }
  }

  List<_QuizCard> _parseQuizContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];

    final normalized = _normalizeQuizContent(trimmed);
    try {
      final dynamic decoded = jsonDecode(normalized);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => _parseQuizItem(item))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        return [_parseQuizItem(decoded)];
      }
    } catch (_) {
      // fallback ke parser teks biasa
    }

    final blocks = normalized
        .split(RegExp(r'\n{2,}'))
        .where((b) => b.trim().isNotEmpty)
        .toList();
    if (blocks.isEmpty) {
      return [_QuizCard(question: trimmed, answer: null)];
    }

    final cards = <_QuizCard>[];
    for (final block in blocks) {
      final normalized = block.trim();
      final answerIndex = normalized.toLowerCase().indexOf('answer:');
      if (answerIndex >= 0) {
        final questionPart = normalized.substring(0, answerIndex).trim();
        final answerPart = normalized.substring(answerIndex + 7).trim();
        cards.add(_QuizCard(question: questionPart, answer: answerPart));
      } else {
        cards.add(_QuizCard(question: normalized, answer: null));
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

  _QuizCard _parseQuizItem(Map<String, dynamic> item) {
    final question =
        item['question']?.toString() ??
        item['text']?.toString() ??
        _getUnknownQuestionText();
    final answer = item['answer']?.toString();
    final explanation = item['explanation']?.toString();
    final type = item['type']?.toString();

    Map<String, String>? options;
    if (item['options'] is Map) {
      options = (item['options'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    return _QuizCard(
      question: question,
      answer: answer,
      explanation: explanation,
      options: options,
      type: type,
    );
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
  final List<_QuizCard> cards;

  const FlashcardResultScreen({
    super.key,
    required this.fileName,
    required this.cards,
  });

  @override
  State<FlashcardResultScreen> createState() => _FlashcardResultScreenState();
}

class _FlashcardResultScreenState extends State<FlashcardResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: Text(
          'Questions from: ${widget.fileName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
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
      ),
    );
  }
}
