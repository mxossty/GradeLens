import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OverallResultsScreen extends StatefulWidget {
  const OverallResultsScreen({super.key});

  @override
  State<OverallResultsScreen> createState() => _OverallResultsScreenState();
}

class _OverallResultsScreenState extends State<OverallResultsScreen> {
  int totalSessions = 0;
  double averagePercentage = 0;
  List<Map<String, dynamic>> rankings = [];
  List<Map<String, dynamic>> sessionRankings = [];
  List<String> subjects = ["All Subjects"];
  String selectedSubject = "All Subjects";
  String selectedSort = "Highest Score";

  Future<void> loadPerformance() async {
    final submissions = await Supabase.instance.client
        .from('student_submissions')
        .select();

    final sessions = await Supabase.instance.client.from('sessions').select();

    subjects = ["All Subjects"];

    for (final session in sessions) {
      final subject = session["subject"];

      if (!subjects.contains(subject)) {
        subjects.add(subject);
      }
    }

    double total = 0;

    for (final submission in submissions) {
      total += (submission['percentage'] ?? 0).toDouble();
    }

    setState(() {
      totalSessions = sessions.length;
      sessionRankings = [];

      for (final session in sessions) {
        final sessionId = session["id"];

        final sessionSubmissions = submissions
            .where((s) => s["session_id"] == sessionId)
            .toList();

        double average = 0;

        if (sessionSubmissions.isNotEmpty) {
          double totalPercentage = 0;

          for (final submission in sessionSubmissions) {
            totalPercentage += (submission["percentage"] ?? 0).toDouble();
          }

          average = totalPercentage / sessionSubmissions.length;
        }

        sessionRankings.add({
          "class_name": session["class_name"],

          "subject": session["subject"],

          "average": average,

          "checked": sessionSubmissions.length,

          "total_students": session["student_count"] ?? 0,
        });
      }

      sessionRankings.sort(
        (a, b) => (b["average"] as double).compareTo(a["average"] as double),
      );

      averagePercentage = submissions.isEmpty ? 0 : total / submissions.length;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPerformance();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRankings = selectedSubject == "All Subjects"
        ? sessionRankings
        : sessionRankings.where((session) {
            return session["subject"] == selectedSubject;
          }).toList();

    int displayedSessions = filteredRankings.length;

    double displayedAverage = 0;

    if (filteredRankings.isNotEmpty) {
      double total = 0;

      for (final session in filteredRankings) {
        total += session["average"] as double;
      }

      displayedAverage = total / filteredRankings.length;
    }

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Performance Overview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedSubject,

                    decoration: InputDecoration(
                      labelText: "Subject",

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    items: subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(
                          subject,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedSort,

                    decoration: InputDecoration(
                      labelText: "Sort",

                      filled: true,

                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: "Highest Score",

                        child: Text(
                          "Highest Score",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      DropdownMenuItem(
                        value: "Lowest Score",

                        child: Text(
                          "Lowest Score",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;

                        if (selectedSort == "Highest Score") {
                          sessionRankings.sort(
                            (a, b) => (b["average"] as double).compareTo(
                              a["average"] as double,
                            ),
                          );
                        } else {
                          sessionRankings.sort(
                            (a, b) => (a["average"] as double).compareTo(
                              b["average"] as double,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: summaryCard("Sessions", displayedSessions.toString()),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: summaryCard(
                    "Average",
                    "${displayedAverage.toStringAsFixed(1)}%",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                "📚 Class Performance Overview",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: filteredRankings.isEmpty
                  ? const Center(
                      child: Text(
                        "No sessions found.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRankings.length,

                      itemBuilder: (context, index) {
                        final data = filteredRankings[index];

                        final checked = (data["checked"] as int).clamp(
                          0,
                          data["total_students"] as int,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),

                          child: rankingCard(
                            data["class_name"] ?? "-",
                            data["subject"] ?? "-",
                            "${(data["average"] as double).toStringAsFixed(1)}%",
                            "$checked/${data["total_students"]}",
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

  Widget summaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.navyBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget rankingCard(
    String className,
    String subject,
    String score,
    String checked,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppColors.navyBlue, size: 24),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  className,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Text("Subject: $subject"),

          SizedBox(height: 8),

          Text("Average: $score"),

          SizedBox(height: 8),

          Text("Students Checked: $checked"),
        ],
      ),
    );
  }
}
