import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'create_session_screen.dart';
import 'class_screen.dart';
import 'overall_results_screen.dart';
import 'session_details_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? latestSession;
  int totalSessions = 0;
  int totalMarked = 0;
  double attendance = 0;
  int latestCheckedStudents = 0;
  int latestTotalStudents = 0;

  @override
  void initState() {
    super.initState();

    loadProfile();
    loadSessionCount();
    loadLatestSession();
    loadDashboardStats();
  }

  Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('email', user?.email ?? '')
        .single();

    setState(() {
      profile = data;
    });
  }

  Future<void> loadLatestSession() async {
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('sessions')
        .select()
        .eq('user_id', user!.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (data.isEmpty) return;

    latestSession = data.first;

    final checked = await Supabase.instance.client
        .from('student_submissions')
        .select('id')
        .eq('session_id', latestSession!['id']);

    latestTotalStudents = latestSession!['student_count'] ?? 0;

    latestCheckedStudents = checked.length.clamp(0, latestTotalStudents);

    setState(() {});
  }

  Future<void> loadDashboardStats() async {
    final user = Supabase.instance.client.auth.currentUser;

    final sessions = await Supabase.instance.client
        .from('sessions')
        .select('id, student_count')
        .eq('user_id', user!.id);

    final sessionIds = sessions.map((e) => e['id']).toList();

    final submissions = sessionIds.isEmpty
        ? []
        : await Supabase.instance.client
        .from('student_submissions')
        .select()
        .inFilter('session_id', sessionIds);

    int expectedStudents = 0;

    for (final session in sessions) {
      expectedStudents += (session['student_count'] ?? 0) as int;
    }

    totalMarked = submissions.length;

    if (expectedStudents > 0) {
      attendance = (totalMarked / expectedStudents) * 100;
    }

    setState(() {});
  }

  Future<void> loadSessionCount() async {
    final user = Supabase.instance.client.auth.currentUser;

    final sessions = await Supabase.instance.client
        .from('sessions')
        .select()
        .eq('user_id', user!.id);

    setState(() {
      totalSessions = sessions.length;
    });
  }

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "GradeLens",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Welcome ${profile?['title'] ?? ''} ${profile?['full_name'] ?? 'Teacher'}",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      "Sessions",
                      totalSessions.toString(),
                      Icons.folder,
                    ),
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: statCard(
                      "Marked",
                      totalMarked.toString(),
                      Icons.description,
                    ),
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: statCard(
                      "Attendance",
                      "${attendance.toStringAsFixed(0)}%",
                      Icons.how_to_reg,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Recent Session",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      latestSession?['class_name'] ?? "No Session",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 18,
                          color: AppColors.navyBlue,
                        ),

                        SizedBox(width: 8),

                        Text(
                          latestSession?['subject'] ?? "",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Question Type: ${latestSession?['question_type'] ?? ''}",
                      style: TextStyle(color: AppColors.textGrey),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Assessment Date: ${latestSession?['assessment_date'] ?? ''}",
                    ),

                    SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: latestTotalStudents == 0
                          ? 0
                          : latestCheckedStudents / latestTotalStudents,
                      minHeight: 10,
                      color: latestCheckedStudents >= latestTotalStudents
                          ? Colors.green
                          : AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "$latestCheckedStudents / $latestTotalStudents students checked",
                    ),

                    SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => SessionDetailsScreen(
                              sessionId: latestSession?['id'] ?? "",
                              className: latestSession?['class_name'] ?? "",
                              subject: latestSession?['subject'] ?? "",
                            ),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: const Text(
                        "Continue →",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const CreateSessionScreen(),
                          ),
                        );
                      },

                      child: actionButton(
                        Icons.add_box_outlined,
                        "Create Session",
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: actionButton(
                      Icons.folder_copy,
                      "My Sessions",

                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const ClassScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: actionButton(
                      Icons.analytics,
                      "Results & Analysis",

                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const OverallResultsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        selectedItemColor: AppColors.navyBlue,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 1) {
            Navigator.push(
              context,

              MaterialPageRoute(builder: (_) => const ClassScreen()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,

              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),

          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Papers",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget actionButton(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 90,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 32, color: AppColors.navyBlue),

            SizedBox(height: 10),

            Text(text),
          ],
        ),
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),

        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),

      child: Column(
        children: [
          Icon(icon, color: AppColors.navyBlue),

          SizedBox(height: 6),

          Text(
            value,

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Text(
            title,

            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
