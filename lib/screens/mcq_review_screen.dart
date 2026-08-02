import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_results_screen.dart';

class MCQReviewScreen extends StatefulWidget {

  final String sessionId;
  final String className;
  final String subject;
  final String submissionId;
  final String studentName;
  final String studentId;
  final String detectedText;
  final List<String> detectedAnswers;
  final String answerSheetPath;


  const MCQReviewScreen({
    super.key,
    required this.answerSheetPath,
    required this.detectedAnswers,
    required this.detectedText,
    required this.studentId,
    required this.studentName,
    required this.submissionId,
    required this.sessionId,
    required this.className,
    required this.subject,
  });

  @override
  State<MCQReviewScreen> createState() =>
      _MCQReviewScreenState();
}

class _MCQReviewScreenState
    extends State<MCQReviewScreen> {

  List<dynamic> questions = [];

  Map<String, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();

    debugPrint("MCQ OCR RECEIVED:");
    debugPrint(widget.detectedText);

    debugPrint("OMR ANSWERS RECEIVED:");
    debugPrint(widget.detectedAnswers.toString());

    loadQuestions();
  }

  Future<void> loadQuestions() async {

    final data = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId)
        .order(
      'question_number',
      ascending: true,
    );

    final savedAnswers = await Supabase.instance.client
        .from('student_answers')
        .select()
        .eq('submission_id', widget.submissionId);

    debugPrint("ARRIVED ANSWERS:");
    debugPrint(widget.detectedAnswers.toString());

    setState(() {

      questions = data;

      for (int i = 0;
      i < questions.length &&
          i < widget.detectedAnswers.length;
      i++) {

        final questionId = questions[i]['id'].toString();

        final saved = savedAnswers.cast<Map<String, dynamic>>().firstWhere(
              (row) => row['question_id'].toString() == questionId,
          orElse: () => {},
        );

        if (saved.isNotEmpty) {

          selectedAnswers[questionId] =
          saved['detected_answer'];

          debugPrint(
              "Loaded SAVED answer for Q${i + 1}: ${saved['detected_answer']}"
          );

        } else {

          selectedAnswers[questionId] =
          widget.detectedAnswers[i];

          debugPrint(
              "Loaded OCR answer for Q${i + 1}: ${widget.detectedAnswers[i]}"
          );

        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Review Students Answers",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,

                itemBuilder: (context, index) {

                  final question =
                  questions[index];

                  final questionId =
                  question['id'].toString();

                  debugPrint(
                      "Question ID: $questionId -> ${selectedAnswers[questionId]}"
                  );

                  debugPrint(
                      "UI Question ID: $questionId"
                  );
                  debugPrint(
                      "UI Value: ${selectedAnswers[questionId]}"
                  );

                  return Card(

                    margin: const EdgeInsets.only(
                      bottom: 20,
                    ),

                    child: Padding(
                      padding:
                      const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Question ${question['question_number']}",

                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          DropdownButtonFormField<String>(

                            value:
                            selectedAnswers[questionId],

                            decoration:
                            const InputDecoration(
                              labelText:
                              "Detected Answer",
                            ),

                            items: const [

                              DropdownMenuItem(
                                value: "A",
                                child: Text("A"),
                              ),

                              DropdownMenuItem(
                                value: "B",
                                child: Text("B"),
                              ),

                              DropdownMenuItem(
                                value: "C",
                                child: Text("C"),
                              ),

                              DropdownMenuItem(
                                value: "D",
                                child: Text("D"),
                              ),

                            ],

                            onChanged: (value) {

                              setState(() {

                                selectedAnswers[
                                questionId
                                ] = value!;

                              });

                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

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

                onPressed: () async {

                  try {

                    int totalScore = 0;
                    int totalMarks = 0;

                    for (var question in questions) {

                      final questionId = question['id'].toString();

                      final mcqAnswer = await Supabase.instance.client
                          .from('mcq_answers')
                          .select()
                          .eq('question_id', questionId)
                          .single();

                      final correctAnswer =
                      mcqAnswer['correct_answer'];

                      final studentAnswer =
                          selectedAnswers[questionId] ?? "";

                      int marksAwarded = 0;

                      if (studentAnswer.toUpperCase() ==
                          correctAnswer.toUpperCase()) {

                        marksAwarded =
                            (question['max_marks'] as num).toInt();

                      }

                      totalScore += marksAwarded;

                      totalMarks +=
                          (question['max_marks'] as num).toInt();

                      await Supabase.instance.client
                          .from('student_answers')
                          .upsert(
                        {
                          'submission_id': widget.submissionId,
                          'question_id': questionId,
                          'detected_answer': studentAnswer,
                          'marks_awarded': marksAwarded,
                        },
                        onConflict: 'submission_id,question_id',
                      );

                    }

                    double percentage = 0;

                    if (totalMarks > 0) {
                      percentage =
                          (totalScore / totalMarks) * 100;
                    }

                    String grade = "F";
                    String status = "Fail";

                    if (percentage >= 80) {

                      grade = "A";
                      status = "Pass";

                    } else if (percentage >= 70) {

                      grade = "B";
                      status = "Pass";

                    } else if (percentage >= 60) {

                      grade = "C";
                      status = "Pass";

                    } else if (percentage >= 50) {

                      grade = "D";
                      status = "Pass";

                    }

                    debugPrint("MCQ SCORE = $totalScore");
                    debugPrint("MCQ TOTAL = $totalMarks");
                    debugPrint("MCQ PERCENT = $percentage");
                    debugPrint("MCQ GRADE = $grade");

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentResultScreen(
                          sessionId: widget.sessionId,

                          studentName: widget.studentName,
                          studentId: widget.studentId,

                          submissionId: widget.submissionId,

                          score: totalScore,
                          totalMarks: totalMarks,
                          grade: grade,
                          percentage: percentage,
                          status: status,
                        ),
                      ),
                    );

                  } catch (e) {

                    debugPrint(e.toString());

                  }

                },

                child: const Text(
                  "Confirm OCR",

                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}