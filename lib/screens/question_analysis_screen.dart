import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'question_details_screen.dart';

class QuestionAnalysisScreen extends StatefulWidget {
  final String sessionId;

  const QuestionAnalysisScreen({super.key, required this.sessionId});

  @override
  State<QuestionAnalysisScreen> createState() => _QuestionAnalysisScreenState();
}

class _QuestionAnalysisScreenState extends State<QuestionAnalysisScreen> {
  List<Map<String, dynamic>> analysis = [];

  List questions = [];

  bool isLoading = true;

  double averageCorrectRate = 0;

  String hardestQuestion = "-";

  String easiestQuestion = "-";

  String aiInsight = "";
  String selectedDifficulty = "All";

  @override
  void initState() {
    super.initState();
    loadAnalysis();
  }

  Future<void> loadAnalysis() async {
    final questionList = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId)
        .order('question_number');

    questions = List.from(questionList);

    analysis.clear();

    for (final question in questions) {
      try {
        final answers = await Supabase.instance.client
            .from('student_answers')
            .select()
            .eq('question_id', question['id']);

        final totalAnswers = answers.length;

        int fullMarksCount = 0;

        for (final answer in answers) {
          if (answer['marks_awarded'] == question['max_marks']) {
            fullMarksCount++;
          }
        }

        double correctRate = 0;

        if (totalAnswers > 0) {
          correctRate = (fullMarksCount / totalAnswers) * 100;
        }

        String difficulty;

        if (correctRate >= 80) {
          difficulty = "🟢 Easy";
        } else if (correctRate >= 50) {
          difficulty = "🟡 Moderate";
        } else {
          difficulty = "🔥 Hard";
        }

        analysis.add({
          "id": question['id'],
          "question": question['question_number'],
          "correctRate": correctRate,
          "difficulty": difficulty,
          "maxMarks": question['max_marks'],
          "subQuestion": question['sub_question'],
        });
      } catch (e) {
        debugPrint("ERROR:");
        debugPrint(e.toString());
      }
    }

    analysis.sort((a, b) => a["correctRate"].compareTo(b["correctRate"]));

    if (analysis.isNotEmpty) {
      double total = 0;

      for (final item in analysis) {
        total += item["correctRate"];
      }

      averageCorrectRate = total / analysis.length;

      analysis.sort((a, b) => a["correctRate"].compareTo(b["correctRate"]));

      hardestQuestion = analysis.first["subQuestion"] == null
          ? "Question ${analysis.first["question"]}"
          : "Question ${analysis.first["question"]}${analysis.first["subQuestion"]}";

      easiestQuestion = analysis.last["subQuestion"] == null
          ? "Question ${analysis.last["question"]}"
          : "Question ${analysis.last["question"]}${analysis.last["subQuestion"]}";
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredAnalysis {
    if (selectedDifficulty == "All") {
      return analysis;
    }

    return analysis
        .where((item) => item["difficulty"].contains(selectedDifficulty))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Question Analysis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: filteredAnalysis.length + 1,

          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "📊 Class Summary",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: "Filter by Difficulty",
                        filled: true,
                        fillColor: AppColors.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Questions"),
                        ),
                        DropdownMenuItem(
                          value: "Hard",
                          child: Text("🔥 Hard"),
                        ),
                        DropdownMenuItem(
                          value: "Moderate",
                          child: Text("🟡 Moderate"),
                        ),
                        DropdownMenuItem(
                          value: "Easy",
                          child: Text("🟢 Easy"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: summaryBox(
                            "${averageCorrectRate.toStringAsFixed(0)}%",
                            "Average",
                            Icons.bar_chart,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: summaryBox(
                            hardestQuestion.replaceAll("Question ", "Q"),
                            "Hardest",
                            Icons.local_fire_department,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: summaryBox(
                            easiestQuestion.replaceAll("Question ", "Q"),
                            "Easiest",
                            Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            final item = filteredAnalysis[index - 1];

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: analysisCard(item),
            );
          },
        ),
      ),
    );
  }

  Widget analysisCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            item["subQuestion"] == null
                ? "Question ${item["question"]}"
                : "Question ${item["question"]}${item["subQuestion"]}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            "${item["correctRate"].toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          const SizedBox(height: 4),

          const Text("Correct Rate", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: item["correctRate"] / 100,

            minHeight: 10,

            borderRadius: BorderRadius.circular(20),

            backgroundColor: Colors.grey.shade200,

            valueColor: AlwaysStoppedAnimation<Color>(
              item["difficulty"].contains("Hard")
                  ? Colors.red
                  : item["difficulty"].contains("Moderate")
                  ? Colors.orange
                  : Colors.green,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: item["difficulty"].contains("Hard")
                  ? Colors.red.shade100
                  : item["difficulty"].contains("Moderate")
                  ? Colors.yellow.shade100
                  : Colors.green.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              item["difficulty"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          //see students answers to the question get to see who is wrong
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionDetailsScreen(
                      questionId: item["id"],
                      questionNumber: item["question"],
                      maxMarks: item["maxMarks"],
                      subQuestion: item["subQuestion"],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),

              label: const Text("View Student Answers"),

              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navyBlue,
                side: const BorderSide(color: AppColors.navyBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),

      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Icon(icon, color: AppColors.navyBlue, size: 26),

          const SizedBox(height: 10),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),

          const SizedBox(height: 4),

          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}