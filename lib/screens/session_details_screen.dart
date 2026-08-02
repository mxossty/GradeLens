import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'front_page_capture_screen.dart';
import 'results_screen.dart';
import 'attendance_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assessment_preview_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final String sessionId;
  final String className;
  final String subject;

  const SessionDetailsScreen({
    super.key,
    required this.sessionId,
    required this.className,
    required this.subject,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  Map<String, dynamic>? session;

  bool hasQuestionPaper = false;
  bool hasKeywords = false;

  int uploadedPapers = 0;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    loadSession();
    loadQuestionStatus();
    loadUploadedPapers();
  }

  Future<void> loadUploadedPapers() async {
    final submissions = await Supabase.instance.client
        .from('student_submissions')
        .select()
        .eq('session_id', widget.sessionId);

    setState(() {
      uploadedPapers = submissions.length;

      final totalStudents = session?['student_count'] ?? 0;

      if (totalStudents > 0) {
        progress = uploadedPapers / totalStudents;
      } else {
        progress = 0;
      }
    });
  }

  Future<void> loadSession() async {
    final data = await Supabase.instance.client
        .from('sessions')
        .select()
        .eq('id', widget.sessionId)
        .single();

    setState(() {
      session = data;
    });

    await loadUploadedPapers();
  }

  Future<void> loadQuestionStatus() async {
    final sessionData = await Supabase.instance.client
        .from('sessions')
        .select('question_type')
        .eq('id', widget.sessionId)
        .single();

    final questionType = sessionData['question_type'];

    final questions = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId);

    bool answerExists = false;

    if (questions.isNotEmpty) {
      for (final question in questions) {

        if (questionType == "MCQ") {
          final answers = await Supabase.instance.client
              .from('mcq_answers')
              .select()
              .eq('question_id', question['id']);

          if (answers.isNotEmpty) {
            answerExists = true;
            break;
          }
        } else {
          final keywords = await Supabase.instance.client
              .from('keywords')
              .select()
              .eq('question_id', question['id']);

          if (keywords.isNotEmpty) {
            answerExists = true;
            break;
          }
        }
      }
    }

    if (!mounted) return;

    setState(() {
      hasQuestionPaper = questions.isNotEmpty;
      hasKeywords = answerExists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Session Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  session?['class_name'] ?? widget.className,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  session?['subject'] ?? widget.subject,
                  style: TextStyle(fontSize: 18, color: AppColors.textGrey),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),

                  child: Column(
                    children: [
                      statusRow(
                        Icons.description,
                        "Question Paper",
                        hasQuestionPaper ? "Uploaded" : "Missing",
                        isSuccess: hasQuestionPaper,
                      ),

                      SizedBox(height: 20),

                      statusRow(
                        Icons.key,
                        session?['question_type'] == "MCQ"
                            ? "Answer Key"
                            : "Keywords",
                        hasKeywords ? "Added" : "Missing",
                        isSuccess: hasKeywords,
                      ),

                      SizedBox(height: 20),

                      statusRow(
                        Icons.people,
                        "Student Papers",
                        "$uploadedPapers / ${session?['student_count'] ?? 0}",
                      ),

                      SizedBox(height: 20),

                      statusRow(
                        Icons.how_to_reg,
                        "Attendance",
                        "$uploadedPapers / ${session?['student_count'] ?? 0} Present",
                      ),

                      SizedBox(height: 20),

                      statusRow(
                        Icons.bar_chart,
                        "Progress",
                        "${(progress * 100).toStringAsFixed(0)}%",
                      ),

                      const SizedBox(height:10),

                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.navyBlue,
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(20),

                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),

                        child: Column(
                          children: [
                            infoRow(
                              Icons.quiz,
                              "Question Type",
                              session?['question_type'] ?? "",
                            ),

                            SizedBox(height: 15),

                            infoRow(
                              Icons.calendar_today,
                              "Created Date",
                              "${session?['assessment_date'] ?? ""}",
                            ),

                            SizedBox(height: 15),

                            infoRow(
                              Icons.people,
                              "Students",
                              "${session?['student_count'] ?? 0}",
                            ),
                          ],
                        ),
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
                          builder: (_) => FrontPageCaptureScreen(
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,

                      padding: const EdgeInsets.symmetric(vertical: 18),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Upload Student Papers",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssessmentPreviewScreen(
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );

                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 10),
                        Text(
                          "View Assessment",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => AttendanceScreen(
                            sessionId: widget.sessionId,
                          ),
                        ),
                      );
                    },

                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),

                      side: BorderSide(color: AppColors.navyBlue),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          color: AppColors.navyBlue,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "View Attendance",
                          style: TextStyle(
                            color: AppColors.navyBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              ResultsScreen(sessionId: widget.sessionId),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics),
                        SizedBox(width: 10),
                        Text(
                          "View Results",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navyBlue),

        SizedBox(width: 15),

        Expanded(child: Text(title)),

        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget statusRow(
      IconData icon,
      String title,
      String value, {
        bool? isSuccess,
      }) {
    return Row(
      children: [

        Icon(icon, color: AppColors.navyBlue),

        const SizedBox(width: 15),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),

        if (isSuccess == null)
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSuccess
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),
      ],
    );
  }
}
