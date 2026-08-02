import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkedAnswersScreen extends StatefulWidget {
  final Map student;

  const MarkedAnswersScreen({super.key, required this.student});

  @override
  State<MarkedAnswersScreen> createState() => _MarkedAnswersScreenState();
}

class _MarkedAnswersScreenState extends State<MarkedAnswersScreen> {
  List answers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAnswers();
  }

  Future<void> loadAnswers() async {
    final data = await Supabase.instance.client
        .from('student_answers')
        .select('''
  *,
  questions (
    question_number,
    sub_question,
    question_text,
    max_marks,
    mcq_answers (
      correct_answer
    )
  )
''')
        .eq('submission_id', widget.student['id']);

    print(data);

    data.sort((a, b) {
      final q1 = a['questions']['question_number'];
      final q2 = b['questions']['question_number'];

      if (q1 != q2) {
        return q1.compareTo(q2);
      }

      return (a['questions']['sub_question'] ?? '').compareTo(
        b['questions']['sub_question'] ?? '',
      );
    });

    setState(() {
      answers = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          "Marked Answers",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: answers.length,

              itemBuilder: (context, index) {
                final answer = answers[index];
                final question = answer['questions'];

                print(question);
                print(question['mcq_answers']);

                final mcqAnswer = question['mcq_answers'];

                final correctAnswer =
                mcqAnswer != null
                    ? mcqAnswer['correct_answer']
                    : "-";

                return Card(
                  margin: const EdgeInsets.only(bottom: 18),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          question['sub_question'] == null
                              ? "Question ${question['question_number']}"
                              : "Question ${question['question_number']}${question['sub_question']}",

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          question['question_text'],
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Student Answer",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Text(answer['detected_answer'] ?? "-"),
                        ),

                        if (question['mcq_answers'] != null) ...[
                          const SizedBox(height: 18),

                          const Text(
                            "Correct Answer",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),

                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Text(
                              correctAnswer,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Text(
                              "Marks Awarded",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const Spacer(),

                            Text(
                              "${answer['marks_awarded']} / ${question['max_marks']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if ((answer['ai_reason'] ?? "")
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 18),

                          const Divider(),

                          const SizedBox(height: 12),

                          const Text(
                            "AI Evaluation",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(answer['ai_reason']),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
