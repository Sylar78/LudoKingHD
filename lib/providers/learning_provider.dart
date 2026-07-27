import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/lessons_data.dart';

class LearningProvider extends ChangeNotifier {
  static const _prefsKey = 'completed_lessons';

  Set<int> _completedLessonIds = {};
  int _currentLessonId = 1;

  Set<int> get completedLessonIds => _completedLessonIds;
  int get currentLessonId => _currentLessonId;

  List<Lesson> get lessons => kLessons;

  bool isUnlocked(int lessonId) {
    if (lessonId == 1) return true;
    return _completedLessonIds.contains(lessonId - 1);
  }

  bool isCompleted(int lessonId) =>
      _completedLessonIds.contains(lessonId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _completedLessonIds = raw.map(int.parse).toSet();
    notifyListeners();
  }

  Future<void> completeLesson(int lessonId) async {
    _completedLessonIds.add(lessonId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _completedLessonIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void setCurrentLesson(int id) {
    _currentLessonId = id;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _completedLessonIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
