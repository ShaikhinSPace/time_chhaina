import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'study_session.g.dart';

@HiveType(typeId: 1)
class StudySession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String subjectId;

  @HiveField(2)
  late DateTime startTime;

  @HiveField(3)
  late DateTime endTime;

  @HiveField(4)
  late int durationInMinutes;

  @HiveField(5)
  late String notes;

  StudySession({
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.notes = '',
  }) {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('End time must be after start time.');
    }

    id = const Uuid().v4(); // Generates a more unique identifier
    durationInMinutes = _calculateDuration();
  }

  int _calculateDuration() => endTime.difference(startTime).inMinutes;

  void updateEndTime(DateTime newEndTime) {
    if (newEndTime.isBefore(startTime)) {
      throw ArgumentError('End time must be after start time.');
    }
    endTime = newEndTime;
    durationInMinutes = _calculateDuration();
    save(); // Ensures Hive persists the change
  }
}
