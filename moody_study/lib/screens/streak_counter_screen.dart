import 'package:flutter/material.dart';

class StreakCounterScreen extends StatelessWidget {
  final int previousStreak;
  final int newStreak;
  final String userName;
  final VoidCallback onContinue;

  const StreakCounterScreen({
    super.key,
    required this.previousStreak,
    required this.newStreak,
    required this.userName,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final gained = newStreak - previousStreak;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF2EA05),
                border: Border(bottom: BorderSide(color: Color(0xFF111111), width: 3)),
              ),
              child: const Text(
                'Streak Counter',
                style: TextStyle(
                  fontFamily: 'BlackHanSans',
                  fontSize: 28,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, size: 88, color: Color(0xFFDD2C00)),
                    const SizedBox(height: 24),
                    Text(
                      'Good job, $userName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 24,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your streak moved from $previousStreak to $newStreak days.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF111111), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFF111111), offset: Offset(4, 4), blurRadius: 0),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildStatRow('Previous streak', previousStreak),
                          const SizedBox(height: 18),
                          _buildStatRow('Current streak', newStreak),
                          const SizedBox(height: 18),
                          _buildStatRow('Gain', gained),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: onContinue,
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF555555)),
        ),
        Text(
          '$value',
          style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
