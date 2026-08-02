import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'question_analysis_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultsScreen extends StatefulWidget {
  final String sessionId;

  const ResultsScreen({super.key, required this.sessionId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List submissions = [];

  int studentsChecked = 0;
  double averageScore = 0;
  String topStudent = "-";
  int pending = 0;
  int totalStudents = 0;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    final data = await Supabase.instance.client
        .from('student_submissions')
        .select()
        .eq('session_id', widget.sessionId);

    submissions = data;

    studentsChecked = submissions.length;

    final session = await Supabase.instance.client
        .from('sessions')
        .select('student_count')
        .eq('id', widget.sessionId)
        .single();

    totalStudents = session['student_count'] ?? 0;

    pending = totalStudents - studentsChecked;

    if (pending < 0) pending = 0;

    double total = 0;
    double highest = -1;

    for (final student in submissions) {
      final percent = (student['percentage'] ?? 0).toDouble();

      total += percent;

      if (percent > highest) {
        highest = percent;
        topStudent =
            "${student['student_name']} - ${percent.toStringAsFixed(0)}%";
      }
    }

    if (studentsChecked > 0) {
      averageScore = total / studentsChecked;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          "Results",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                resultCard(
                  Icons.people,
                  "Students Checked",
                  "$studentsChecked / ${submissions.length}",
                ),

                const SizedBox(height: 15),

                resultCard(
                  Icons.bar_chart,
                  "Average Score",
                  "${averageScore.toStringAsFixed(1)}%",
                ),

                const SizedBox(height: 15),

                resultCard(Icons.emoji_events, "Top Student", topStudent),

                const SizedBox(height: 15),

                resultCard(Icons.pending_actions, "Pending", "$pending papers"),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assessment Status",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: totalStudents == 0
                                  ? 0
                                  : studentsChecked / totalStudents,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade300,
                              color: AppColors.navyBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            totalStudents == 0
                                ? "0%"
                                : "${((studentsChecked / totalStudents) * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "$studentsChecked of $totalStudents papers completed",
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            color: AppColors.navyBlue,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "$pending paper${pending == 1 ? "" : "s"} remaining",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => QuestionAnalysisScreen(
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,

                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),

                    child: const Text(
                      "View Question Analysis",

                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget resultCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: ListTile(
        leading: Icon(icon, color: AppColors.navyBlue),

        title: Text(title),

        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
