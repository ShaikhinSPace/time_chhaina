// File: lib/screens/home_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_chhaina/providers/provider.dart';
import '../models/subject.dart';
import 'subject_detail_screen.dart';
import 'add_subject_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final activeSession = ref.watch(activeStudySessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text('Time Chhaina - Study Timer'),
        actions: [
          if (activeSession.isActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Studying', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No subjects added yet',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 69, 69, 69),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddSubjectScreen(),
                        ),
                      );
                    },
                    child: const Text('Add Your First Subject'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final isActive =
                  activeSession.isActive &&
                  activeSession.subjectId == subject.id;

              return SubjectListTile(subject: subject, isActive: isActive);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        shape: const CircleBorder(),
        backgroundColor: const Color.fromARGB(255, 69, 69, 69),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const AddSubjectScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubjectListTile extends ConsumerWidget {
  final Subject subject;
  final bool isActive;

  const SubjectListTile({
    required this.subject,
    required this.isActive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalStudyTimeAsync = ref.watch(totalStudyTimeProvider(subject.id));

    return Card(
      color: const Color.fromARGB(255, 80, 80, 80),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectDetailScreen(subject: subject),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(int.parse(subject.color)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    totalStudyTimeAsync.when(
                      data: (totalMinutes) {
                        final hours = totalMinutes ~/ 60;
                        final minutes = totalMinutes % 60;
                        return Text(
                          'Total: ${hours}h ${minutes}m',
                          style: TextStyle(color: Colors.white),
                        );
                      },
                      loading: () => const Text('Calculating...'),
                      error: (_, __) => const Text('Error calculating time'),
                    ),
                  ],
                ),
              ),
              if (isActive)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    _showStopSessionDialog(context, ref);
                  },
                  child: const Text(
                    'Stop',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    ref
                        .read(activeStudySessionProvider.notifier)
                        .startSession(subject.id);
                  },
                  child: const Text(
                    'Start',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStopSessionDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Study Session'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Subject: ${subject.name}'),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(activeStudySessionProvider.notifier)
                      .stopSession(notes: notesController.text);
                  Navigator.pop(context);
                  ref.refresh(subjectsProvider);
                  ref.refresh(totalStudyTimeProvider(subject.id));
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
