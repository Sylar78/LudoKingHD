import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/lessons_data.dart';
import '../providers/learning_provider.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _stepIndex = 0;
  late Lesson _lesson;

  @override
  void initState() {
    super.initState();
    _lesson = kLessons.firstWhere((l) => l.id == widget.lessonId);
  }

  void _next() {
    if (_stepIndex < _lesson.steps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      _completeLesson();
    }
  }

  void _prev() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _completeLesson() async {
    final lp = context.read<LearningProvider>();
    await lp.completeLesson(_lesson.id);
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CompletionDialog(lesson: _lesson),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _lesson.steps[_stepIndex];
    final total = _lesson.steps.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B69),
        foregroundColor: Colors.white,
        title: Text('${_lesson.icon} ${_lesson.title}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Étape ${_stepIndex + 1} / $total',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      Text('Leçon ${_lesson.id}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_stepIndex + 1) / total,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C4DFF)),
                    ),
                  ),
                ],
              ),
            ),

            // Step card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.3, 0), end: Offset.zero)
                        .animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _StepCard(
                      key: ValueKey(_stepIndex), step: step, lesson: _lesson),
                ),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_stepIndex > 0)
                    OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(_stepIndex == total - 1
                        ? Icons.check_circle
                        : Icons.arrow_forward),
                    label:
                        Text(_stepIndex == total - 1 ? 'Terminer' : 'Suivant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _stepIndex == total - 1
                          ? Colors.green
                          : const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ).animate().scale(duration: 200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final LessonStep step;
  final Lesson lesson;

  const _StepCard({super.key, required this.step, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF1A1035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF7C4DFF).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.2), blurRadius: 20)
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              step.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 16),
            Text(
              step.body,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final Lesson lesson;
  const _CompletionDialog({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D1B69),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(
              'Leçon ${lesson.id} terminée !',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${lesson.icon} ${lesson.title}',
              style: const TextStyle(color: Colors.amber, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24)),
                  child: const Text('Retour'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
