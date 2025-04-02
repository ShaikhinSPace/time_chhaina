// File: lib/models/subject.dart

import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String color;

  @HiveField(3)
  late List<String> sessionIds;

  Subject({required this.name, required this.color, List<String>? sessionIds}) {
    this.id = DateTime.now().millisecondsSinceEpoch.toString();
    this.sessionIds = sessionIds ?? [];
  }
}
