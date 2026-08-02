import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'upload_student_papers_screen.dart';
import 'front_page_capture_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentVerificationScreen extends StatefulWidget {

  final String sessionId;

  final String detectedName;
  final String detectedId;
  final String detectedClass;

  const StudentVerificationScreen({
    super.key,
    required this.sessionId,
    required this.detectedName,
    required this.detectedId,
    required this.detectedClass,
  });

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState
    extends State<StudentVerificationScreen> {

  final nameController =
  TextEditingController();

  final classController =
  TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController.text =
        widget.detectedName;

    classController.text =
        widget.detectedClass;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Verify Student",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Please make sure the student's name and class are correct before continuing.",
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Student Name",

                prefixIcon:
                const Icon(Icons.person),

                filled: true,
                fillColor: Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: classController,
              decoration: InputDecoration(
                labelText: "Class",

                prefixIcon:
                const Icon(Icons.class_),

                filled: true,
                fillColor: Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.navyBlue,

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),

                onPressed: isSaving
                    ? null
                    : () async {

                  setState(() {
                    isSaving = true;
                  });

                  try {

                    final session = await Supabase.instance.client
                        .from('sessions')
                        .select()
                        .eq('id', widget.sessionId)
                        .single();

                    final currentSubmissions = await Supabase.instance.client
                        .from('student_submissions')
                        .select()
                        .eq('session_id', widget.sessionId);

                    final maxStudents = session['student_count'] ?? 0;

                    if (maxStudents > 0 &&
                        currentSubmissions.length >= maxStudents) {

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Session Full"),
                          content: Text(
                            "This session already contains the maximum of $maxStudents students.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      setState(() {
                        isSaving = false;
                      });

                      return;
                    }

                    final submission = await Supabase.instance.client
                        .from('student_submissions')
                        .insert({
                      'session_id': widget.sessionId,
                      'student_name': nameController.text,
                      'student_id': '',
                      'class_name': classController.text,
                    })
                        .select()
                        .single();

                    final className = session['class_name'];
                    final studentCount = session['student_count'];
                    final questionType = session['question_type'];

                    final submissionId = submission['id'];

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UploadStudentPapersScreen(
                              sessionId: widget.sessionId,
                              submissionId: submissionId,
                              studentName: nameController.text,
                              studentId: '',
                              className: className,
                              studentCount: studentCount,
                              questionType: questionType,
                            )
                      ),
                    );

                  } catch (e) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      SnackBar(
                        content: Text("Error: $e"),
                      ),

                    );

                    if (mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  }

                },

                child: isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}