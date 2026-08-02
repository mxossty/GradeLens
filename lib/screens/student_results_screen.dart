import 'package:flutter/material.dart';
import 'package:gradelens_new/screens/upload_student_papers_screen.dart';
import '../theme/app_colors.dart';
import 'results_screen.dart';
import 'class_screen.dart';
import 'front_page_capture_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentResultScreen extends StatelessWidget {

  final String sessionId;
  final String studentName;
  final String studentId;
  final String submissionId;

  final int score;
  final int totalMarks;
  final String grade;
  final double percentage;
  final String status;

  const StudentResultScreen({
    super.key,
    required this.sessionId,
    required this.studentName,
    required this.studentId,
    required this.submissionId,

    required this.score,
    required this.totalMarks,
    required this.grade,
    required this.percentage,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Student Result",

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

            const CircleAvatar(
              radius:40,
              child: Icon(
                Icons.person,
                size:40,
              ),
            ),

            const SizedBox(height:20),

            Text(
              studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:30),

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius:5,
                  )
                ],
              ),

              child: Column(
                children: [

                  resultRow(
                    "Score",
                    "$score / $totalMarks",
                  ),

                  SizedBox(height:15),

                  resultRow(
                    "Grade",
                    grade,
                  ),

                  SizedBox(height:15),

                  resultRow(
                    "Percentage",
                    "${percentage.toStringAsFixed(0)}%",
                  ),

                  SizedBox(height:15),

                  resultRow(
                    "Status",
                    status,
                  ),

                ],
              ),
            ),

            Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: () async {

                  await Supabase.instance.client
                      .from('student_submissions')
                      .update({

                    'score': score,
                    'total_score': score,
                    'total_marks': totalMarks,
                    'percentage': percentage,
                    'grade': grade,
                    'status': status,

                  })
                      .eq('id', submissionId);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FrontPageCaptureScreen(
                        sessionId: sessionId,
                      ),
                    ),
                  );

                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.navyBlue,

                  padding:
                  const EdgeInsets.symmetric(
                    vertical:18,
                  ),
                ),

                child: const Text(
                  "Save & Continue",

                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height:15),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton(

                onPressed: () async {

                  await Supabase.instance.client
                      .from('student_submissions')
                      .update({

                    'score': score,
                    'total_score': score,
                    'total_marks': totalMarks,
                    'percentage': percentage,
                    'grade': grade,
                    'status': status,

                  })
                      .eq('id', submissionId);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassScreen(),
                    ),
                  );

                },

                style:
                OutlinedButton.styleFrom(

                  side: BorderSide(
                    color: AppColors.navyBlue,
                  ),

                  padding:
                  const EdgeInsets.symmetric(
                    vertical:18,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),

                child: Text(
                  "Stop Here",

                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize:16,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget resultRow(
      String title,
      String value){

    return Row(
      children:[

        Expanded(
          child: Text(title),
        ),

        Text(
          value,

          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        )

      ],
    );
  }
}