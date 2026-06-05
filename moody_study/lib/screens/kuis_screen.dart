import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:moody_study/core/failure.dart';
import 'package:moody_study/core/exception_handler.dart';
import '../models/generated_quiz_response.dart';
import '../services/material_service.dart';
import 'oddy_flashcard_screen.dart';

class KuisScreen extends StatefulWidget {
  const KuisScreen({super.key});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  List<GeneratedQuizResponse> _savedQuizzes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<Either<Failure, List<GeneratedQuizResponse>>> _fetchSaved() async {
    try {
      return Right(await MaterialService.getSavedQuizzes());
    } catch (e) {
      return Left(ServiceFailure(sanitizeException(e)));
    }
  }

  Future<void> _loadSaved() async {
    setState(() { _loading = true; _error = null; });
    final result = await _fetchSaved();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _error = failure.message; _loading = false; }),
      (quizzes) => setState(() { _savedQuizzes = quizzes; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1EE86F)))
                  : _error != null
                      ? _buildError()
                      : _savedQuizzes.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EA05),
        border: Border(bottom: BorderSide(color: Color(0xFF111111), width: 3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kuis Tersimpan',
            style: TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 22,
              color: Color(0xFF111111),
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_savedQuizzes.length} set',
              style: const TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 13,
                color: Color(0xFFF2EA05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada kuis tersimpan',
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 18,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buka flashcard dari tab File,\nlalu tap ikon 🔖 untuk menyimpan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDD2C00)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF555555))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadSaved,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EA05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF111111), width: 2),
                boxShadow: const [BoxShadow(color: Color(0xFF111111), offset: Offset(3, 3))],
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: Color(0xFF111111))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: const Color(0xFF1EE86F),
      onRefresh: _loadSaved,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _savedQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = _savedQuizzes[index];
          final cards = _parseQuizCards(quiz.quizContent);
          return _SavedQuizCard(
            quiz: quiz,
            cardCount: cards.length,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FlashcardResultScreen(
                  fileName: quiz.fileName,
                  cards: cards,
                  quizId: quiz.id,
                  isSaved: quiz.saved,
                ),
              ));
              _loadSaved(); // refresh in case user unsaved
            },
            onUnsave: () async {
              await MaterialService.toggleSaveQuiz(quiz.id);
              _loadSaved();
            },
          );
        },
      ),
    );
  }

  List<QuizCard> _parseQuizCards(String quizContent) {
    final normalized = _normalizeQuizContent(quizContent);
    final decoded = _decodePotentialJson(normalized);
    final cards = <QuizCard>[];

    if (decoded is List) {
      for (final item in decoded) {
        final card = _tryParseQuizItem(item);
        if (card != null) cards.add(card);
      }
    } else if (decoded is Map<String, dynamic>) {
      final list = <dynamic>[];
      if (decoded['questions'] is List) {
        list.addAll(decoded['questions'] as List);
      } else if (decoded['items'] is List) {
        list.addAll(decoded['items'] as List);
      } else if (decoded['cards'] is List) {
        list.addAll(decoded['cards'] as List);
      } else if (decoded['data'] is List) {
        list.addAll(decoded['data'] as List);
      } else if (decoded.containsKey('question')) {
        list.add(decoded);
      } else if (decoded['quizContent'] is String) {
        return _parseQuizCards(decoded['quizContent'] as String);
      } else if (decoded['content'] is String) {
        return _parseQuizCards(decoded['content'] as String);
      } else if (decoded['payload'] is String) {
        return _parseQuizCards(decoded['payload'] as String);
      } else if (decoded['data'] is String) {
        return _parseQuizCards(decoded['data'] as String);
      } else {
        list.add(decoded);
      }

      for (final item in list) {
        final card = _tryParseQuizItem(item);
        if (card != null) cards.add(card);
      }
    }

    if (cards.isNotEmpty) return cards;

    return _parsePlainTextQuizCards(normalized);
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

  Either<Failure, dynamic> _tryDecodeJson(String value) {
    try {
      return Right(jsonDecode(value));
    } catch (e) {
      return Left(ParseFailure(sanitizeException(e)));
    }
  }

  dynamic _decodePotentialJson(String value) {
    var current = value.trim();
    for (var i = 0; i < 3; i++) {
      final result = _tryDecodeJson(current);
      if (result.isLeft()) break;
      final decoded = result.getOrElse(() => current);
      if (decoded is String) {
        current = decoded.trim();
        continue;
      }
      return decoded;
    }

    // Try to recover JSON content inside a text block.
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
      final options = item['options'] is Map
          ? (item['options'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : null;
      final explanation = item['explanation']?.toString();
      final type = item['type']?.toString();

      if (question.isEmpty && answer == null) {
        return null;
      }

      return QuizCard(
        question: question.isNotEmpty ? question : 'Question unavailable',
        answer: answer,
        options: options,
        explanation: explanation,
        type: type,
      );
    }

    if (item is String) {
      final decoded = _decodePotentialJson(item);
      if (decoded is Map<String, dynamic>) return _tryParseQuizItem(decoded);
      if (decoded is List) return _tryParseQuizItem(decoded.first);

      final extracted = _extractQuestionAnswerFromRaw(item);
      if (extracted != null) return extracted;
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

  List<QuizCard> _parsePlainTextQuizCards(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];

    final normalized = _normalizeQuizContent(trimmed);
    final blocks = normalized.split(RegExp(r'\n{2,}')).where((b) => b.trim().isNotEmpty).toList();
    if (blocks.isEmpty) return [QuizCard(question: normalized)];

    return blocks.map((block) {
      final parsed = _extractQuestionAnswerFromRaw(block);
      if (parsed != null) return parsed;
      final answerIndex = block.toLowerCase().indexOf('answer:');
      if (answerIndex >= 0) {
        final questionPart = block.substring(0, answerIndex).trim();
        final answerPart = block.substring(answerIndex + 7).trim();
        return QuizCard(question: questionPart, answer: answerPart);
      }
      return QuizCard(question: block.trim());
    }).toList();
  }
}

// ── Quiz card widget ─────────────────────────────────────────────────────────

class _SavedQuizCard extends StatelessWidget {
  final GeneratedQuizResponse quiz;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedQuizCard({
    required this.quiz,
    required this.cardCount,
    required this.onTap,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF111111), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EA05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF111111), width: 2),
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.fileName,
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 14,
                      color: Color(0xFF111111),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8FFF1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1EE86F), width: 1.5),
                        ),
                        child: Text(
                          '$cardCount soal',
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 11,
                            color: Color(0xFF1A9A50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        quiz.generatedAt.substring(0, 10),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Unsave button
            IconButton(
              onPressed: onUnsave,
              icon: const Icon(
                Icons.bookmark_rounded,
                color: Color(0xFFF2EA05),
                size: 26,
              ),
              tooltip: 'Hapus dari Kuis',
            ),
          ],
        ),
      ),
    );
  }
}