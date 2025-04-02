// File: lib/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_chhaina/services/db_service.dart';
import '../models/subject.dart';
import '../models/study_session.dart';

// Subject providers
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return await DatabaseService.getSubjects();
});

// Active study session provider
final activeStudySessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, StudySessionState>((ref) {
      return ActiveSessionNotifier();
    });

class StudySessionState {
  final bool isActive;
  final String? subjectId;
  final DateTime? startTime;

  StudySessionState({this.isActive = false, this.subjectId, this.startTime});

  StudySessionState copyWith({
    bool? isActive,
    String? subjectId,
    DateTime? startTime,
  }) {
    return StudySessionState(
      isActive: isActive ?? this.isActive,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<StudySessionState> {
  ActiveSessionNotifier() : super(StudySessionState());

  void startSession(String subjectId) {
    state = StudySessionState(
      isActive: true,
      subjectId: subjectId,
      startTime: DateTime.now(),
    );
  }

  Future<void> stopSession({String notes = ''}) async {
    if (state.isActive && state.subjectId != null && state.startTime != null) {
      final session = StudySession(
        subjectId: state.subjectId!,
        startTime: state.startTime!,
        endTime: DateTime.now(),
        notes: notes,
      );

      await DatabaseService.addSession(session);
      state = StudySessionState();
    }
  }
}

// Sessions by subject provider
final sessionsBySubjectProvider =
    FutureProvider.family<List<StudySession>, String>((ref, subjectId) async {
      return await DatabaseService.getSessionsBySubject(subjectId);
    });

// Total study time by subject provider
final totalStudyTimeProvider = FutureProvider.family<int, String>((
  ref,
  subjectId,
) async {
  final sessions = await DatabaseService.getSessionsBySubject(subjectId);
  int totalDuration = 0;
  for (final session in sessions) {
    totalDuration += session.durationInMinutes;
  }
  return totalDuration;
});
