import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionDetailsScreen extends StatefulWidget {

  final int questionNumber;
  final String questionId;
  final int maxMarks;
  final String? subQuestion;

  const QuestionDetailsScreen({
    super.key,
    required this.maxMarks,
    required this.questionId,
    required this.questionNumber,
    this.subQuestion,
  });

  @override
  State<QuestionDetailsScreen> createState() =>
      _QuestionDetailsScreenState();
}

class _QuestionDetailsScreenState
    extends State<QuestionDetailsScreen> {

  List answers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAnswers();
  }

  Future<void> loadAnswers() async {

    final data =
    await Supabase.instance.client
        .from('student_answers')
        .select('''
      *,
      student_submissions (
        student_name
      )
    ''')
        .eq('question_id', widget.questionId);

    answers = data;

    debugPrint(data.toString());

    debugPrint("ANSWERS:");
    debugPrint(answers.toString());

    setState(() {
      isLoading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: Text(
          widget.subQuestion == null
              ? "Question ${widget.questionNumber}"
              : "Question ${widget.questionNumber}${widget.subQuestion}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: answers.length,
        itemBuilder: (context, index) {

          final answer = answers[index];

          String feedback;

          if (answer["marks_awarded"] > 0) {
            feedback =
            "Excellent! The student's answer matches the expected answer.";
          } else {
            feedback =
            "The answer does not match the expected keywords. Review this topic.";
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [

                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                      answer["marks_awarded"] == widget.maxMarks
                          ? Colors.green
                          : answer["marks_awarded"] > 0
                          ? Colors.orange
                          : Colors.red,
                      child: Text(
                        ((answer["student_submissions"]?["student_name"] ?? "").isNotEmpty)
                            ? answer["student_submissions"]["student_name"]
                            .substring(0, 1)
                            .toUpperCase()
                            : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        answer["student_submissions"]?["student_name"] ??
                            "Unknown Student",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 15),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "📝 Student Answer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(

                        color: Colors.grey.shade100,

                        borderRadius: BorderRadius.circular(15),

                      ),

                      child: Text(
                        answer["detected_answer"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Icon(
                        Icons.smart_toy,
                        color: AppColors.navyBlue,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Answer Feedback",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              feedback,
                              style: const TextStyle(
                                height: 1.5,
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),
          );
        },
      )
    );
  }
}
