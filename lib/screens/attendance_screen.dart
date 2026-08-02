import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_report_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AttendanceScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceScreen({super.key, required this.sessionId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List students = [];
  List filteredStudents = [];

  final TextEditingController searchController = TextEditingController();
  String selectedFilter = "All";
  String selectedSort = "Name";

  int totalStudents = 0;
  int presentStudents = 0;
  int absentStudents = 0;
  double classAverage = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final data = await Supabase.instance.client
        .from('student_submissions')
        .select()
        .eq('session_id', widget.sessionId);

    students = data;

    filteredStudents = List.from(students);

    final session = await Supabase.instance.client
        .from('sessions')
        .select('student_count')
        .eq('id', widget.sessionId)
        .single();

    totalStudents = session["student_count"] ?? 0;

    presentStudents = students.length;

    absentStudents = totalStudents - presentStudents;

    if (absentStudents < 0) {
      absentStudents = 0;
    }

    double totalPercentage = 0;
    int gradedStudents = 0;

    for (final student in students) {
      if (student["grade"] != null) {
        totalPercentage += (student["percentage"] ?? 0).toDouble();

        gradedStudents++;
      }
    }

    if (gradedStudents > 0) {
      classAverage = totalPercentage / gradedStudents;
    }

    debugPrint(students.toString());

    setState(() {
      isLoading = false;
    });
  }

  Future<void> editStudent(Map student) async {

    final nameController = TextEditingController(
      text: student["student_name"],
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {

        return AlertDialog(

          title: const Text("Edit Student"),

          content: TextField(
            controller: nameController,

            decoration: const InputDecoration(
              labelText: "Student Name",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                debugPrint(student.toString());

                try {

                  debugPrint("Trying to update...");
                  debugPrint("ID: ${student["id"]}");
                  debugPrint("New Name: ${nameController.text}");

                  await Supabase.instance.client
                      .from("student_submissions")
                      .update({
                    "student_name": nameController.text.trim(),
                  })
                      .eq("id", student["id"]);

                  debugPrint("UPDATE SUCCESS");

                } catch (e) {

                  debugPrint("UPDATE ERROR");
                  debugPrint(e.toString());

                }

                Navigator.pop(context, true);

              },

              child: const Text("Save"),
            ),

          ],
        );

      },
    );

    if (result == true) {

      await loadStudents();

    }

  }

  Future<void> deleteStudent(Map student) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(

        title: const Text("Delete Student"),

        content: Text(
          "Delete ${student["student_name"]}?\n\nThis action cannot be undone.",
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),

        ],
      ),
    );

    if (confirm != true) return;

    debugPrint(student.toString());

    try {

      debugPrint("Deleting...");
      debugPrint("ID: ${student["id"]}");

      await Supabase.instance.client
          .from("student_submissions")
          .delete()
          .eq("id", student["id"]);

      debugPrint("DELETE SUCCESS");

    } catch (e) {

      debugPrint("DELETE ERROR");
      debugPrint(e.toString());

    }

    await loadStudents();
  }

  void searchStudent(String value) {
    setState(() {
      filteredStudents = students.where((student) {
        final name = (student["student_name"] ?? "").toString().toLowerCase();

        final grade = (student["grade"] ?? "").toString().toUpperCase();

        final matchesName = name.contains(value.toLowerCase());

        final matchesGrade = selectedFilter == "All" || grade == selectedFilter;

        return matchesName && matchesGrade;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text("Attendance", style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: summaryBox(
                        totalStudents.toString(),
                        "Students",
                        Icons.people,
                        AppColors.navyBlue,
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 110,
                      child: summaryBox(
                        presentStudents.toString(),
                        "Present",
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 110,
                      child: summaryBox(
                        absentStudents.toString(),
                        "Absent",
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 110,
                      child: summaryBox(
                        "${classAverage.toStringAsFixed(1)}%",
                        "Average Marks",
                        Icons.bar_chart,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5),
                        ],
                      ),

                      child: TextField(
                        controller: searchController,
                        onChanged: searchStudent,

                        decoration: InputDecoration(
                          hintText: "Search student...",
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),

                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: "All", child: Text("All")),
                          DropdownMenuItem(value: "A", child: Text("A")),
                          DropdownMenuItem(value: "B", child: Text("B")),
                          DropdownMenuItem(value: "C", child: Text("C")),
                          DropdownMenuItem(value: "D", child: Text("D")),
                          DropdownMenuItem(value: "F", child: Text("F")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                            searchStudent(searchController.text);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Student Overview (${filteredStudents.length})",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSort,
                            items: const [
                              DropdownMenuItem(
                                value: "Name",
                                child: Text("Name"),
                              ),
                              DropdownMenuItem(
                                value: "Marks",
                                child: Text("Marks"),
                              ),
                              DropdownMenuItem(
                                value: "Percentage",
                                child: Text("Percentage"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSort = value!;

                                if (selectedSort == "Name") {
                                  filteredStudents.sort(
                                    (a, b) =>
                                        a["student_name"].toString().compareTo(
                                          b["student_name"].toString(),
                                        ),
                                  );
                                }

                                if (selectedSort == "Marks") {
                                  filteredStudents.sort(
                                    (a, b) => (b["total_score"] ?? 0).compareTo(
                                      a["total_score"] ?? 0,
                                    ),
                                  );
                                }

                                if (selectedSort == "Percentage") {
                                  filteredStudents.sort(
                                    (a, b) => (b["percentage"] ?? 0).compareTo(
                                      a["percentage"] ?? 0,
                                    ),
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];

                        return studentCard(student);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget absentStudent(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red,

            child: Icon(Icons.close, color: Colors.white, size: 18),
          ),

          const SizedBox(width: 12),

          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget studentCard(Map student) {
    return Slidable(
      key: ValueKey(student['id']),

      endActionPane: ActionPane(
        motion: const DrawerMotion(),

        children: [
          SlidableAction(
            onPressed: (context) {
              editStudent(student);
            },

            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: "Edit",
          ),

          SlidableAction(
            onPressed: (context) {

              deleteStudent(student);

            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: "Delete",
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentReportScreen(student: student),
            ),
          );
        },

        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.green,

                child: Text(
                  (student["student_name"] ?? "?")
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      student["student_name"] ?? "",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Present",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${student["total_score"] ?? 0} / ${student["total_marks"] ?? 0} Marks",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        Text(
                          "${(student['percentage'] ?? 0).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    LinearProgressIndicator(
                      value: (student["percentage"] ?? 0) / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(20),

                      backgroundColor: Colors.grey.shade200,

                      valueColor: AlwaysStoppedAnimation<Color>(
                        (student["percentage"] ?? 0) >= 80
                            ? Colors.green
                            : (student["percentage"] ?? 0) >= 50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: student["grade"] == "A"
                            ? Colors.green.shade100
                            : student["grade"] == "B"
                            ? Colors.lightGreen.shade100
                            : student["grade"] == "C"
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Grade ${student["grade"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: student["grade"] == "A"
                              ? Colors.green.shade800
                              : student["grade"] == "B"
                              ? Colors.lightGreen.shade800
                              : student["grade"] == "C"
                              ? Colors.orange.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 26),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: student["grade"] == "A"
                          ? Colors.green.shade100
                          : student["grade"] == "B"
                          ? Colors.lightGreen.shade100
                          : student["grade"] == "C"
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      student["grade"] ?? "-",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: student["grade"] == "A"
                            ? Colors.green.shade800
                            : student["grade"] == "B"
                            ? Colors.lightGreen.shade800
                            : student["grade"] == "C"
                            ? Colors.orange.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
