// File: lib/screens/subject_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_chhaina/providers/provider.dart';
import 'package:time_chhaina/services/db_service.dart';
import '../models/subject.dart';
import '../models/study_session.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final Subject subject;

  const SubjectDetailScreen({required this.subject, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsBySubjectProvider(subject.id));
    final totalTimeAsync = ref.watch(totalStudyTimeProvider(subject.id));
    final activeSession = ref.watch(activeStudySessionProvider);
    final isActive =
        activeSession.isActive && activeSession.subjectId == subject.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        backgroundColor: Color(int.parse(subject.color)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Study Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        totalTimeAsync.when(
                          data: (totalMinutes) {
                            final hours = totalMinutes ~/ 60;
                            final minutes = totalMinutes % 60;
                            return Text(
                              '${hours}h ${minutes}m',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('Error'),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _showStopSessionDialog(context, ref);
                      },
                      child: const Text('Stop Studying'),
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
                      child: const Text('Start Studying'),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Text(
                  'Study Sessions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text('No study sessions recorded yet'),
                  );
                }

                // Sort sessions by date (newest first)
                sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return SessionListTile(session: session);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Subject'),
            content: Text(
              'Are you sure you want to delete "${subject.name}"? All study sessions for this subject will also be deleted. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await DatabaseService.deleteSubject(subject.id);
                  ref.refresh(subjectsProvider);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to home screen
                },
                child: const Text('Delete'),
              ),
            ],
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
                  ref.refresh(sessionsBySubjectProvider(subject.id));
                  ref.refresh(totalStudyTimeProvider(subject.id));
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class SessionListTile extends StatelessWidget {
  final StudySession session;

  const SessionListTile({required this.session, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final dateFormat = DateTime('MMM d, yyyy');
    // final timeFormat = DateFormat('h:mm a');

    final formattedDate =
        session.startTime.toLocal().toString().split(
          ' ',
        )[0]; // Format date as 'MMM d, yyyy'ß
    final startTime = session.startTime;
    final endTime = session.endTime;

    final hours = session.durationInMinutes ~/ 60;
    final minutes = session.durationInMinutes % 60;
    final duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$startTime - $endTime'),
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(session.notes),
            ],
          ],
        ),
      ),
    );
  }
}
