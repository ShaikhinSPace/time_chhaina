// File: lib/services/database_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/adapters.dart' as adapters;

class DatabaseService {
  static const String subjectsBoxName = 'subjects';
  static const String sessionsBoxName = 'study_sessions';

  static Future<void> initialize() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register the manual adapters instead of waiting for generated ones
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(adapters.SubjectAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudySessionAdapter());
    }

    await Hive.openBox<Subject>(subjectsBoxName);
    await Hive.openBox<StudySession>(sessionsBoxName);
  }

  // Subject Methods
  static Future<List<Subject>> getSubjects() async {
    final box = Hive.box<Subject>(subjectsBoxName);
    return box.values.toList();
  }

  static Future<void> addSubject(Subject subject) async {
    final box = Hive.box<Subject>(subjectsBoxName);
    await box.put(subject.id, subject);
  }

  static Future<void> updateSubject(Subject subject) async {
    final box = Hive.box<Subject>(subjectsBoxName);
    await box.put(subject.id, subject);
  }

  static Future<void> deleteSubject(String id) async {
    final box = Hive.box<Subject>(subjectsBoxName);
    await box.delete(id);

    // Also delete any associated sessions
    final sessionsBox = Hive.box<StudySession>(sessionsBoxName);
    final sessions =
        sessionsBox.values.where((s) => s.subjectId == id).toList();
    for (var session in sessions) {
      await sessionsBox.delete(session.id);
    }
  }

  static Subject? getSubject(String id) {
    final box = Hive.box<Subject>(subjectsBoxName);
    return box.get(id);
  }

  // Session Methods
  static Future<List<StudySession>> getSessions() async {
    final box = Hive.box<StudySession>(sessionsBoxName);
    return box.values.toList();
  }

  static Future<List<StudySession>> getSessionsBySubject(
    String subjectId,
  ) async {
    final box = Hive.box<StudySession>(sessionsBoxName);
    return box.values
        .where((session) => session.subjectId == subjectId)
        .toList();
  }

  static Future<void> addSession(StudySession session) async {
    final box = Hive.box<StudySession>(sessionsBoxName);
    await box.put(session.id, session);

    // Update subject with new session ID
    final subjectsBox = Hive.box<Subject>(subjectsBoxName);
    final subject = subjectsBox.get(session.subjectId);
    if (subject != null) {
      subject.sessionIds.add(session.id);
      await subjectsBox.put(subject.id, subject);
    }
  }

  static Future<void> updateSession(StudySession session) async {
    final box = Hive.box<StudySession>(sessionsBoxName);
    await box.put(session.id, session);
  }

  static Future<void> deleteSession(String id) async {
    final sessionsBox = Hive.box<StudySession>(sessionsBoxName);
    final session = sessionsBox.get(id);

    if (session != null) {
      // Remove session ID from subject
      final subjectsBox = Hive.box<Subject>(subjectsBoxName);
      final subject = subjectsBox.get(session.subjectId);
      if (subject != null) {
        subject.sessionIds.remove(id);
        await subjectsBox.put(subject.id, subject);
      }

      // Delete the session
      await sessionsBox.delete(id);
    }
  }
}
