import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'session_summary_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_questions_screen.dart';

class AddKeywordsScreen extends StatefulWidget {

  final String className;
  final String sessionId;
  final String subject;
  final int studentCount;
  final String questionType;
  final bool isEditing;

  const AddKeywordsScreen({
    super.key,
    required this.sessionId,
    required this.className,
    required this.subject,
    required this.questionType,
    required this.studentCount,
    this.isEditing = false,
  });

  @override
  State<AddKeywordsScreen> createState() =>
      _AddKeywordsScreenState();
}

class _AddKeywordsScreenState
    extends State<AddKeywordsScreen> {

  Map<String, TextEditingController>
  keywordControllers = {};

  Map<String, TextEditingController>
  questionTextControllers = {};

  Map<String, TextEditingController>
  marksControllers = {};

  Map<String, TextEditingController>
  subQuestionControllers = {};

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
        .select('*, keywords(keyword)')
        .eq('session_id', widget.sessionId)
        .order(
      'question_number',
      ascending: true,
    )
        .order(
      'sub_question',
      ascending: true,
    );

    for (final question in data) {

      final questionId = question['id'];

      final keywordList =
          question['keywords'] as List<dynamic>? ?? [];

      questionTextControllers[questionId] =
          TextEditingController(
            text: question['question_text'] ?? '',
          );

      marksControllers[questionId] =
          TextEditingController(
            text: question['max_marks'].toString(),
          );

      subQuestionControllers[questionId] =
          TextEditingController(
            text: question['sub_question'] ?? '',
          );

      keywordControllers[questionId] =
          TextEditingController(
            text: keywordList
                .map((k) => k['keyword'])
                .join('\n'),
          );
    }

    setState(() {
      questions = data;
    });

    for (final question in questions) {

      final questionId = question['id'];

      final keywordList = question['keywords'] as List<dynamic>? ?? [];

      keywordControllers[questionId] = TextEditingController(
        text: keywordList
            .map((k) => k['keyword'])
            .join('\n'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: const Text(
          "Subjective Keywords",
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

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,

                itemBuilder: (context, index) {

                  final question = questions[index];

                  final questionId =
                  question['id'];

                  return Card(

                    margin: const EdgeInsets.only(
                      bottom: 30,
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(

                            question['sub_question'] == null
                                ? "Question ${question['question_number']}"
                                : "Question ${question['question_number']}${question['sub_question']}",

                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller:
                            questionTextControllers[questionId],
                            maxLines: 5,

                            decoration: const InputDecoration(
                              labelText: "Question Text",
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              Expanded(
                                child: TextField(
                                  controller:
                                  subQuestionControllers[questionId],

                                  decoration: const InputDecoration(
                                    labelText: "Sub Question",
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: TextField(
                                  controller:
                                  marksControllers[questionId],
                                  keyboardType: TextInputType.number,

                                  decoration: const InputDecoration(
                                    labelText: "Marks",
                                  ),
                                ),
                              ),

                            ],
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller:
                            keywordControllers[questionId],

                            maxLines: 4,

                            decoration: InputDecoration(

                              hintText:
                              "Enter keywords\n(one per line)",

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    15),
                              ),
                            ),
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

              child: OutlinedButton.icon(

                onPressed: () async {

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(

                      title: const Text(
                        "Re-upload Question Paper",
                      ),

                      content: const Text(
                        "This will delete all extracted questions and keywords for this session.\n\nYou will need to upload the question paper again.\n\nContinue?",
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
                            "Re-upload",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),

                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {

                    // Delete all extracted questions
                    await Supabase.instance.client
                        .from('questions')
                        .delete()
                        .eq('session_id', widget.sessionId);

                    if (!context.mounted) return;

                    final session = await Supabase.instance.client
                        .from('sessions')
                        .select()
                        .eq('id', widget.sessionId)
                        .single();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPaperScreen(
                          sessionId: widget.sessionId,
                          className: session['class_name'],
                          subject: session['subject'],
                          questionType: session['question_type'],
                          assessmentDate: DateTime.parse(session['assessment_date']),
                          studentCount: session['student_count'],
                          mcqQuestionCount: session['mcq_question_count'] ?? 0,
                        ),
                      ),
                    );

                  } catch (e) {

                    print(e);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Failed to reset the question paper.",
                        ),
                      ),
                    );

                    return;

                  }

                },

                icon: const Icon(
                  Icons.refresh,
                  color: Colors.red,
                ),

                label: const Text(
                  "Re-upload Question Paper",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                  ),

                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.navyBlue,

                  padding:
                  EdgeInsets.symmetric(
                    vertical:18,
                  ),
                ),

                onPressed: isSaving
                    ? null
                    : () async {

                  if (questions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No questions found."),
                      ),
                    );
                    return;
                  }

                  if (!context.mounted) return;

                  setState(() {
                    isSaving = true;
                  });

                  try {

                    for (var question in questions) {

                      final questionId = question['id'];

                      debugPrint("Question: ${question['question_number']}");
                      debugPrint("Question ID: $questionId");
                      debugPrint("marksControllers contains key: ${marksControllers.containsKey(questionId)}");

                      debugPrint("marksController = ${marksControllers[questionId]}");
                      debugPrint("questionController = ${questionTextControllers[questionId]}");
                      debugPrint("subController = ${subQuestionControllers[questionId]}");

                      final marks = int.tryParse(
                        marksControllers[questionId]?.text ?? "",
                      );

                      if (marks == null || marks < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Please enter valid marks for Question ${question['question_number']}.",
                            ),
                          ),
                        );
                        return;
                      }

                      if (questionTextControllers[questionId]!.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Question ${question['question_number']} cannot be empty.",
                            ),
                          ),
                        );
                        return;
                      }

                      debugPrint("questionText = ${questionTextControllers[questionId]?.text}");
                      debugPrint("subQuestion = ${subQuestionControllers[questionId]?.text}");
                      debugPrint("marks = ${marksControllers[questionId]?.text}");
                      await Supabase.instance.client
                          .from('questions')
                          .update({
                        'question_text':
                          questionTextControllers[questionId]?.text ?? "",

                        'sub_question':
                          subQuestionControllers[questionId]?.text ?? "",
                        'max_marks': marks,

                      })
                          .eq('id', questionId);

                      await Supabase.instance.client
                          .from('keywords')
                          .delete()
                          .eq('question_id', questionId);

                      final controller =
                      keywordControllers[questionId];

                      if (controller == null ||
                          controller.text.trim().isEmpty) {
                        continue;
                      }

                      final keywords =
                      controller.text.split('\n');

                      for (String keyword in keywords) {

                        if (keyword.trim().isNotEmpty) {

                          await Supabase.instance.client
                              .from('keywords')
                              .insert({

                            'question_id': questionId,
                            'keyword': keyword.trim(),

                          });

                        }
                      }
                    }

                    if (!context.mounted) return;

                    if (widget.isEditing) {

                      Navigator.pop(context, true);
                      return;

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

                  } catch (e, stackTrace) {

                    debugPrint("========== ERROR ==========");
                    debugPrint(e.toString());

                    debugPrint("========== STACK ==========");
                    debugPrint(stackTrace.toString());

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );

                  } finally {

                    if (mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }

                  }

                },


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
                      : "Save Keywords",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}