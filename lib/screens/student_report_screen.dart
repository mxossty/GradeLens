import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import "marked_answers_screen.dart";

class StudentReportScreen extends StatefulWidget {

  final Map student;

  const StudentReportScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentReportScreen> createState() =>
      _StudentReportScreenState();
}

class _StudentReportScreenState
    extends State<StudentReportScreen> {

  String aiFeedback = "";
  String aiRecommendation = "";
  bool isLoading = true;
  String performance = "";

  @override
  void initState() {
    super.initState();
    generateAIReport();
  }

  Future<void> generateAIReport() async {

    if ((widget.student["percentage"] ?? 0) >= 80) {

      performance = "🏆 Excellent Performance";

      aiFeedback =
      "The student demonstrates an excellent understanding of the topic.";

      aiRecommendation =
      "Continue practising advanced questions to maintain performance.";

    } else if ((widget.student["percentage"] ?? 0) >= 50) {

      performance = "👍 Good Performance";

      aiFeedback =
      "The student has a satisfactory understanding but made several mistakes.";

      aiRecommendation =
      "Review the incorrect questions and revise the related topics.";

    } else {

      performance = "⚠ Needs Improvement";

      aiFeedback =
      "The student struggles with this assessment and requires additional support.";

      aiRecommendation =
      "Revise the basic concepts and practise similar questions.";

    }

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
        title: const Text(
          "Student Report",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Center(
              child: Text(
                widget.student["student_name"] ?? "",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (widget.student["percentage"] ?? 0) >= 80
                      ? Colors.green.shade100
                      : (widget.student["percentage"] ?? 0) >= 50
                      ? Colors.orange.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  performance,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (widget.student["percentage"] ?? 0) >= 80
                        ? Colors.green.shade800
                        : (widget.student["percentage"] ?? 0) >= 50
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
            ),

            const SizedBox(height:30),

            reportTile(
              Icons.grade,
              "Marks",
              "${widget.student["total_score"] ?? 0} / ${widget.student["total_marks"] ?? 0}",
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [

                  Row(
                    children: [

                      Icon(
                        Icons.bar_chart,
                        color: AppColors.navyBlue,
                      ),

                      const SizedBox(width: 15),

                      const Expanded(
                        child: Text(
                          "Percentage",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        "${(widget.student["percentage"] ?? 0).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (widget.student["percentage"] ?? 0) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (widget.student["percentage"] ?? 0) >= 80
                            ? Colors.green
                            : (widget.student["percentage"] ?? 0) >= 50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            reportTile(
              Icons.school,
              "Grade",
              "${widget.student["grade"] ?? "-"}",
            ),

            const SizedBox(height: 15),

            aiCard(
              "🤖 Performance Feedback",
              aiFeedback,
            ),

            const SizedBox(height: 15),

            aiCard(
              "💡 Study Recommendation",
              aiRecommendation,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text("View Marked Answers"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkedAnswersScreen(
                        student: widget.student,
                      ),
                    ),
                  );

                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget reportTile(
      IconData icon,
      String title,
      String value,
      ) {

    return Container(
      margin: const EdgeInsets.only(bottom:16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius:5,
          ),
        ],
      ),

      child: Row(

        children: [

          Icon(
            icon,
            color: AppColors.navyBlue,
          ),

          const SizedBox(width:15),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: title == "Grade"
                  ? (value == "A"
                  ? Colors.green.shade100
                  : value == "B"
                  ? Colors.lightGreen.shade100
                  : value == "C"
                  ? Colors.orange.shade100
                  : Colors.red.shade100)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: title == "Grade"
                    ? (value == "A"
                    ? Colors.green
                    : value == "B"
                    ? Colors.lightGreen
                    : value == "C"
                    ? Colors.orange
                    : Colors.red)
                    : Colors.black,
              ),
            ),
          )

        ],
      ),
    );
  }

  Widget aiCard(
      String title,
      String content,
      ) {

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

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

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            isLoading
                ? "Generating..."
                : content,
            style: const TextStyle(
              height: 1.5,
              fontSize: 15,
            ),
          ),

        ],
      ),
    );
  }
}
