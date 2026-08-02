import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

class AssessmentPreviewScreen extends StatefulWidget {
  final String sessionId;

  const AssessmentPreviewScreen({super.key, required this.sessionId});

  @override
  State<AssessmentPreviewScreen> createState() =>
      _AssessmentPreviewScreenState();
}

class _AssessmentPreviewScreenState extends State<AssessmentPreviewScreen> {
  List questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final data = await Supabase.instance.client
        .from('questions')
        .select('''
        *,
        keywords (
          keyword
        ),
        mcq_answers (
          correct_answer
        )
      ''')
        .eq('session_id', widget.sessionId)
        .order('question_number', ascending: true)
        .order('sub_question', ascending: true);

    print(data);

    setState(() {
      questions = data;
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
          "Assessment Preview",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 18),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          question["sub_question"] == null
                              ? "Question ${question["question_number"]}"
                              : "Question ${question["question_number"]}${question["sub_question"]}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          question["question_text"] ?? "",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Text(
                              "Maximum Marks",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const Spacer(),

                            Text(
                              "${question["max_marks"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        if (question["keywords"] != null &&
                            question["keywords"].isNotEmpty) ...[
                          const Text(
                            "Keywords",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 10),

                          ...question["keywords"].map<Widget>((keyword) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(child: Text(keyword["keyword"])),
                                ],
                              ),
                            );
                          }).toList(),
                        ],

                        if (question["mcq_answers"] != null &&
                            question["mcq_answers"].isNotEmpty) ...[
                          const Text(
                            "Correct Answer",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),

                            child: Text(
                              question['mcq_answers']?['correct_answer'] ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
