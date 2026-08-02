import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'upload_questions_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? session;

  const CreateSessionScreen({super.key, this.session});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final classController = TextEditingController();

  final subjectController = TextEditingController();

  final studentCountController = TextEditingController();

  final questionCountController = TextEditingController();

  String questionType = "MCQ";
  DateTime? selectedDate;

  bool get isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();

    if (widget.session != null) {
      classController.text = widget.session!['class_name'] ?? '';

      subjectController.text = widget.session!['subject'] ?? '';

      studentCountController.text = widget.session!['student_count'].toString();

      questionType = widget.session!['question_type'];

      questionCountController.text =
          widget.session!['mcq_question_count']?.toString() ?? '';

      selectedDate = DateTime.parse(widget.session!['assessment_date']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: Text(
          isEditing ? "Edit Session" : "Create Assessment Session",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),

            TextField(
              controller: classController,
              decoration: InputDecoration(
                labelText: "Class Name",

                prefixIcon: Icon(Icons.class_),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: "Subject",

                prefixIcon: Icon(Icons.menu_book),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: studentCountController,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                labelText: "Number of Students",

                prefixIcon: Icon(Icons.people),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            SizedBox(height: 20),

            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2035),
                );

                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },

              child: Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: Colors.grey),
                ),

                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),

                    const SizedBox(width: 12),

                    Text(
                      selectedDate == null
                          ? "Assessment Date"
                          : "${selectedDate!.day}/"
                                "${selectedDate!.month}/"
                                "${selectedDate!.year}",

                      style: TextStyle(
                        color: selectedDate == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(15),

                border: Border.all(color: Colors.grey),
              ),

              child: DropdownButtonFormField(
                isExpanded: true,

                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.quiz),
                ),

                value: questionType,

                items: const [
                  DropdownMenuItem(value: "MCQ", child: Text("Multiple Choice Questions (MCQs)")),

                  DropdownMenuItem(value: "Subjective", child: Text("Subjective")),
                ],

                onChanged: (value) {
                  setState(() {
                    questionType = value.toString();
                  });
                },
              ),
            ),

            if (questionType == "MCQ") ...[
              const SizedBox(height: 20),

              TextField(
                controller: questionCountController,
                keyboardType: TextInputType.number,

                decoration: InputDecoration(
                  labelText: "Number of MCQ Questions",

                  prefixIcon: const Icon(Icons.format_list_numbered),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,

                  padding: EdgeInsets.symmetric(vertical: 18),
                ),

                onPressed: () async {
                  if (classController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a class name."),
                      ),
                    );
                    return;
                  }

                  if (subjectController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a subject.")),
                    );
                    return;
                  }

                  if (studentCountController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter the number of students."),
                      ),
                    );
                    return;
                  }

                  // Validation 4
                  final studentCount = int.tryParse(
                    studentCountController.text,
                  );

                  if (studentCount == null || studentCount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Student count must be greater than 0."),
                      ),
                    );
                    return;
                  }

                  // Validation 5
                  if (selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select an assessment date."),
                      ),
                    );
                    return;
                  }

                  // Validation 6
                  int? mcqCount;

                  if (questionType == "MCQ") {
                    mcqCount = int.tryParse(questionCountController.text);

                    if (mcqCount == null || mcqCount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter a valid number of MCQ questions.",
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  try {
                    final supabase = Supabase.instance.client;

                    Map<String, dynamic> sessionData = {
                      'class_name': classController.text.trim(),

                      'subject': subjectController.text.trim(),

                      'student_count': studentCount,

                      'question_type': questionType,

                      'mcq_question_count': questionType == "MCQ"
                          ? mcqCount
                          : null,

                      'assessment_date': selectedDate?.toIso8601String(),
                    };

                    dynamic session;

                    if (isEditing) {

                      print("========== EDIT ==========");
                      print("Session ID: ${widget.session!['id']}");
                      print("Editing session:");
                      print(widget.session);
                      print(widget.session!['id']);
                      print(sessionData);

                      await supabase
                          .from('sessions')
                          .update(sessionData)
                          .eq('id', widget.session!['id']);

                      session = widget.session!;
                    } else {
                      session = await supabase
                          .from('sessions')
                          .insert(sessionData)
                          .select()
                          .single();
                    }

                    final sessionId = session['id'];

                    if (isEditing) {
                      if (!mounted) return;

                      Navigator.pop(context, true);

                      return;
                    }

                    print("MCQ?SUBJECTIVE Session ID: $sessionId");

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPaperScreen(
                          sessionId: sessionId,
                          className: classController.text,
                          subject: subjectController.text,
                          questionType: questionType,
                          assessmentDate: selectedDate!,
                          studentCount: studentCount,
                          mcqQuestionCount: questionType == "MCQ"
                              ? mcqCount!
                              : 0,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },

                child: Text(
                  isEditing ? "Save Changes" : "Create & Continue",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
