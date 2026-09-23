import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../widgets/app_background.dart';
import 'lesson_screen.dart';

class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Apprendre à jouer'),
        actions: [
          TextButton(
            onPressed: () => _confirmReset(context, lp),
            child: const Text('Réinitialiser',
                style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
      body: AppBackground(
        showGlows: false,
        child: SafeArea(
          child: Column(
            children: [
              _ProgressHeader(lp: lp),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lp.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lp.lessons[index];
                    final unlocked = lp.isUnlocked(lesson.id);
                    final completed = lp.isCompleted(lesson.id);

                    return _LessonTile(
                      lesson: lesson,
                      unlocked: unlocked,
                      completed: completed,
                      index: index,
                      onTap: unlocked
                          ? () {
                              lp.setCurrentLesson(lesson.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        LessonScreen(lessonId: lesson.id)),
                              );
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, LearningProvider lp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser la progression ?'),
        content: const Text('Cela effacera toutes les leçons terminées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (ok == true) await lp.resetProgress();
  }
}

class _ProgressHeader extends StatelessWidget {
  final LearningProvider lp;
  const _ProgressHeader({required this.lp});

  @override
  Widget build(BuildContext context) {
    final completed = lp.completedLessonIds.length;
    final total = lp.lessons.length;
    final pct = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2D1B69),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed / $total leçons terminées',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${(pct * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final dynamic lesson;
  final bool unlocked;
  final bool completed;
  final int index;
  final VoidCallback? onTap;

  const _LessonTile({
    required this.lesson,
    required this.unlocked,
    required this.completed,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Connector line
          Column(
            children: [
              if (index > 0)
                Container(width: 2, height: 12, color: Colors.white24),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? Colors.green
                      : unlocked
                          ? const Color(0xFF7C4DFF)
                          : Colors.grey.shade700,
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : !unlocked
                          ? const Icon(Icons.lock,
                              color: Colors.white54, size: 16)
                          : Text(lesson.icon,
                              style: const TextStyle(fontSize: 16)),
                ),
              ),
              Container(width: 2, height: 12, color: Colors.white24),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(0.15)
                      : unlocked
                          ? const Color(0xFF2D1B69)
                          : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: completed
                        ? Colors.green.withOpacity(0.5)
                        : unlocked
                            ? const Color(0xFF7C4DFF).withOpacity(0.5)
                            : Colors.grey.shade800,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(lesson.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leçon ${lesson.id} · ${lesson.title}',
                            style: TextStyle(
                              color: unlocked
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${lesson.steps.length} étapes',
                            style: TextStyle(
                                color: unlocked
                                    ? Colors.white54
                                    : Colors.grey.shade700,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (completed)
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    if (unlocked && !completed)
                      const Icon(Icons.play_circle_outline,
                          color: Color(0xFF7C4DFF), size: 20),
                    if (!unlocked)
                      const Icon(Icons.lock_outline,
                          color: Colors.grey, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
