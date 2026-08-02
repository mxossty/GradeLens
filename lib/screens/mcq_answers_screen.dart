import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'session_summary_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class McqAnswersScreen extends StatefulWidget {

  final String className;
  final String sessionId;
  final String subject;
  final String questionType;
  final int studentCount;
  final bool isEditing;

  const McqAnswersScreen({
    super.key,
    required this.sessionId,
    required this.className,
    required this.subject,
    required this.questionType,
    required this.studentCount,
    this.isEditing = false,
  });

  @override
  State<McqAnswersScreen> createState() =>
      _McqAnswersScreenState();
}

class _McqAnswersScreenState
    extends State<McqAnswersScreen> {

  Map<String, String> selectedAnswers = {};

  List<dynamic> questions = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {

    final data = await Supabase.instance.client
        .from('questions')
        .select('*, mcq_answers(correct_answer)')
        .eq('session_id', widget.sessionId)
        .order('question_number');

    data.sort(
          (a, b) => a['question_number']
          .compareTo(b['question_number']),
    );

    print(data);

    for (var question in data) {

      if (question['mcq_answers'] != null) {

        selectedAnswers[question['id']] =
        question['mcq_answers']['correct_answer'];
      }

      String text = question['question_text'] ?? "";

      // Remove question numbers
      text = text.replaceFirst(
        RegExp(r'^\d+\.\s*'),
        '',
      );

      // Remove all [x marks]
      text = text.replaceAll(
        RegExp(r'\[\d+\s*marks?\]', caseSensitive: false),
        '',
      );

      // Remove extra spaces/newlines
      text = text.trim();

      question['question_text'] = text;
    }

    setState(() {
      questions = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Objective/MCQ Answer Keys",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(15),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    "Class: ${widget.className}",
                  ),

                  Text(
                    "Subject: ${widget.subject}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,

                itemBuilder: (context, index) {

                  final question = questions[index];

                  return Card(

                    margin: const EdgeInsets.only(bottom: 20),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Question ${question['question_number']}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            initialValue: question['question_text'] ?? "",

                            maxLines: null,

                            decoration: const InputDecoration(
                              labelText: "Question",
                              border: OutlineInputBorder(),
                            ),

                            onChanged: (value) {
                              question['question_text'] = value;
                            },
                          ),

                          const SizedBox(height: 15),

                          TextFormField(
                            initialValue: question['max_marks'].toString(),

                            keyboardType: TextInputType.number,

                            decoration: const InputDecoration(
                              labelText: "Marks",
                              border: OutlineInputBorder(),
                            ),

                            onChanged: (value) {

                              question['max_marks'] =
                                  int.tryParse(value) ?? 1;

                            },
                          ),

                          const SizedBox(height: 15),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,

                            children: [

                              buildAnswerCard(
                                question['id'],
                                "A",
                              ),

                              buildAnswerCard(
                                question['id'],
                                "B",
                              ),

                              buildAnswerCard(
                                question['id'],
                                "C",
                              ),

                              buildAnswerCard(
                                question['id'],
                                "D",
                              ),

                            ],
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

                onPressed: isSaving
                    ? null
                    : () async {

                  setState(() {
                    isSaving = true;
                  });

                  try {

                    for (var question in questions) {

                      final questionId = question['id'];

                      if ((question['question_text'] ?? "").trim().isEmpty) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Question ${question['question_number']} is empty.",
                            ),
                          ),
                        );

                        return;
                      }

                      if ((question['max_marks'] ?? 0) <= 0) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Please enter valid marks for Question ${question['question_number']}.",
                            ),
                          ),
                        );

                        return;
                      }

                      if (!selectedAnswers.containsKey(questionId)) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Please choose the correct answer for Question ${question['question_number']}.",
                            ),
                          ),
                        );

                        return;
                      }
                    }

                    for (var question in questions) {

                      final questionId = question['id'];

                      final answer =
                      selectedAnswers[questionId];

                      if (answer == null) continue;

                      await Supabase.instance.client
                          .from('questions')
                          .update({

                        'question_text': question['question_text'],
                        'max_marks': question['max_marks'],

                      })
                          .eq('id', questionId);

                      await Supabase.instance.client
                          .from('mcq_answers')
                          .upsert(
                        {
                          'question_id': questionId,
                          'correct_answer': answer,
                        },
                        onConflict: 'question_id',
                      );
                    }

                    if (!context.mounted) return;

                    if (widget.isEditing) {

                      Navigator.pop(context, true);

                    } else {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionSummaryScreen(
                            className: widget.className,
                            subject: widget.subject,
                            questionType: widget.questionType,
                            studentCount: widget.studentCount,
                          ),
                        ),
                      );

                    }

                  } catch (e) {

                    print(e);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Something went wrong. Please try again.",
                        ),
                      ),
                    );
                  }

                  finally {
                    if (mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  }
                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.navyBlue,

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),

                child: isSaving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  widget.isEditing
                      ? "Save Changes"
                      : "Continue",
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

  Widget buildAnswerCard(
      String questionId,
      String option,
      ) {

    bool isSelected =
        selectedAnswers[questionId] == option;

    return GestureDetector(

      onTap: () {

        setState(() {

          selectedAnswers[questionId] =
              option;

        });

      },

      child: Container(

        width: 70,
        height: 60,

        decoration: BoxDecoration(

          color: isSelected
              ? AppColors.navyBlue
              : Colors.white,

          borderRadius:
          BorderRadius.circular(12),

          border: Border.all(
            color: AppColors.navyBlue,
          ),
        ),

        child: Center(

          child: Text(

            option,

            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : AppColors.navyBlue,
            ),
          ),
        ),
      ),
    );
  }
}