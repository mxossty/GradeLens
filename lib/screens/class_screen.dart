import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'session_details_screen.dart';
import 'create_session_screen.dart';
import 'dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mcq_answers_screen.dart';
import 'add_keywords_screen.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  Future<List<Map<String, dynamic>>> getSessions() async {
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('sessions')
        .select()
        .eq('user_id', user!.id);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> deleteSession(String sessionId) async {
    await Supabase.instance.client
        .from('sessions')
        .delete()
        .eq('id', sessionId);

    setState(() {});
  }

  Future<int> getCheckedStudents(String sessionId) async {
    final data = await Supabase.instance.client
        .from('student_submissions')
        .select('id')
        .eq('session_id', sessionId);

    return data.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),

          onPressed: () {
            Navigator.push(
              context,

              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),

        title: const Text(
          "My Sessions",

          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navyBlue,

        onPressed: () {
          Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getSessions(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!;

            if (sessions.isEmpty) {
              return const Center(child: Text("No sessions found"));
            }

            return ListView.builder(
              itemCount: sessions.length,

              itemBuilder: (context, index) {
                final session = sessions[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),

                  child: sessionCard(context, session),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget sessionCard(BuildContext context, Map<String, dynamic> session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailsScreen(
              sessionId: session['id'],
              className: session['class_name'],
              subject: session['subject'],
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),

        child: Stack(
          children: [
            FutureBuilder<int>(
              future: getCheckedStudents(session['id']),
              builder: (context, snapshot) {
                final checkedStudents = snapshot.data ?? 0;

                final totalStudents = session['student_count'] ?? 0;

                // Never let the UI exceed the total
                final displayedChecked = checkedStudents.clamp(
                  0,
                  totalStudents,
                );

                final progress = totalStudents == 0
                    ? 0.0
                    : displayedChecked / totalStudents;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['class_name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(session['subject']),

                    const SizedBox(height: 15),

                    LinearProgressIndicator(
                      value: progress,
                      color: progress >= 1 ? Colors.green : AppColors.navyBlue,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    const SizedBox(height: 10),

                    Text("$displayedChecked / $totalStudents students checked"),
                  ],
                );
              },
            ),

            Positioned(
              top: 8,
              right: 8,

              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),

                onSelected: (value) async {
                  if (value == "open") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailsScreen(
                          sessionId: session['id'],
                          className: session['class_name'],
                          subject: session['subject'],
                        ),
                      ),
                    );
                  }

                  if (value == "edit") {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateSessionScreen(session: session),
                      ),
                    );

                    if (updated == true) {
                      setState(() {});
                    }
                  }

                  if (value == "edit_mcq") {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => McqAnswersScreen(
                          sessionId: session['id'],
                          className: session['class_name'],
                          subject: session['subject'],
                          questionType: session['question_type'],
                          studentCount: session['student_count'],
                          isEditing: true,
                        ),
                      ),
                    );

                    if (updated == true) {
                      setState(() {});
                    }
                  }

                  if (value == "editSubjective") {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddKeywordsScreen(
                          sessionId: session['id'],
                          className: session['class_name'],
                          subject: session['subject'],
                          questionType: session['question_type'],
                          studentCount: session['student_count'],
                          isEditing: true,
                        ),
                      ),
                    );

                    if (updated == true) {
                      setState(() {});
                    }
                  }

                  if (value == "delete") {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Session"),
                        content: const Text(
                          "Are you sure you want to delete this session?\n\nThis action cannot be undone.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text("Cancel"),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await deleteSession(session['id']);
                    }
                  }
                },

                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "open",
                    child: Text("Open Session"),
                  ),

                  const PopupMenuItem(
                    value: "edit",
                    child: Text("Edit Session Information"),
                  ),

                  if (session['question_type'] == "MCQ")
                    const PopupMenuItem(
                      value: "edit_mcq",
                      child: Text("Edit MCQ Answer Key"),
                    )
                  else
                    const PopupMenuItem(
                      value: "editSubjective",
                      child: Text("Edit Subjective Assessment"),
                    ),

                  const PopupMenuItem(
                    value: "delete",
                    child: Text("Delete Session"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
