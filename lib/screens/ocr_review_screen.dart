import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'student_results_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';

class OCRReviewScreen extends StatefulWidget {
  final String sessionId;
  final String studentName;
  final Map<String, String> detectedAnswers;
  final String studentId;
  final String submissionId;
  final Map<String, dynamic> aiResults;
  final String className;

  const OCRReviewScreen({
    super.key,
    required this.className,
    required this.sessionId,
    required this.studentName,
    required this.studentId,
    required this.detectedAnswers,
    required this.submissionId,
    required this.aiResults,
  });

  @override
  State<OCRReviewScreen> createState() => _OCRReviewScreenState();
}

class _OCRReviewScreenState extends State<OCRReviewScreen> {
  List<dynamic> questions = [];
  Map<String, TextEditingController> answerControllers = {};
  Map<String, TextEditingController> markControllers = {};
  bool isSaving = false;
  Map<String, int> estimatedMarks = {};
  Map<String, int> aiMarks = {};
  Set<String> completedQuestions = {};
  Map<String, int> aiConfidence = {};
  Map<String, String> aiReasons = {};
  Map<String, bool> aiLoading = {};
  Map<String, bool> teacherEdited = {};
  int completedAI = 0;

  Future<void> loadQuestions() async {
    completedAI = 0;
    completedQuestions.clear();
    estimatedMarks.clear();
    aiMarks.clear();
    aiConfidence.clear();
    aiReasons.clear();
    aiLoading.clear();
    teacherEdited.clear();
    answerControllers.clear();

    final data = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId)
        .order('question_number', ascending: true)
        .order('sub_question', ascending: true);

    questions = data;
    List<Future> aiTasks = [];

    // Calculate AI estimated marks
    for (final question in questions) {
      final questionId = question['id'];

      final answerKey =
          "Q${question['question_number']}${question['sub_question'] ?? ''}";

      final answer = (widget.detectedAnswers[answerKey] ?? "").toLowerCase();

      final keywords = await Supabase.instance.client
          .from('keywords')
          .select()
          .eq('question_id', questionId);

      int matchedKeywords = 0;

      for (final keyword in keywords) {
        final keywordText = keyword['keyword'].toString().toLowerCase();

        if (answer.contains(keywordText)) {
          matchedKeywords++;
        }
      }

      int estimated = 0;

      if (keywords.isNotEmpty) {
        estimated =
            ((matchedKeywords / keywords.length) * question['max_marks'])
                .round();
      }

      estimatedMarks[questionId] = estimated;

      if (widget.aiResults.containsKey(questionId)) {
        final result = widget.aiResults[questionId];

        aiMarks[questionId] = (result["marks"] ?? estimated) as int;
        aiConfidence[questionId] = (result["confidence"] ?? 0) as int;
        aiReasons[questionId] = result["reason"] ?? "No explanation available.";

        aiLoading[questionId] = false;

        debugPrint("Loaded AI for $questionId");
        debugPrint(result.toString());
      } else {
        aiLoading[questionId] = true;

        aiTasks.add(verifyQuestionAI(question, keywords, answer, estimated));
      }
    }

    await Future.wait(aiTasks);
    setState(() {});
  }

  Future<void> verifyQuestionAI(
    dynamic question,
    List<dynamic> keywords,
    String answer,
    int estimated,
  ) async {
    final questionId = question['id'];

    final keywordList = keywords.map((e) => e['keyword'].toString()).toList();

    final result = await GeminiService.verifyAnswer(
      question: question['question_text'],
      keywords: keywordList,
      studentAnswer: answer,
      maxMarks: (question['max_marks'] as num).toInt(),
      nlpMarks: estimated,
    );

    if (!mounted) return;

    setState(() {
      aiMarks[questionId] = result["marks"];
      markControllers[questionId]?.text = result["marks"].toString();
      teacherEdited[questionId] = false;
      aiConfidence[questionId] = result["confidence"];
      aiReasons[questionId] = result["reason"];

      if ((result["confidence"] ?? -1) != -1 &&
          !completedQuestions.contains(questionId)) {
        completedQuestions.add(questionId);
        completedAI++;
      }

      aiLoading[questionId] = false;
    });
  }

  @override
  void dispose() {
    for (var controller in answerControllers.values) {
      controller.dispose();
    }

    for (var controller in markControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    debugPrint("RECEIVED ANSWERS:");
    debugPrint(widget.detectedAnswers.toString());

    debugPrint("LENGTH:");
    debugPrint(widget.detectedAnswers.length.toString());

    loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review Students Answer",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.studentName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 18),

              decoration: BoxDecoration(
                color: completedAI == questions.length && questions.isNotEmpty
                    ? Colors.green.shade50
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completedAI == questions.length && questions.isNotEmpty
                        ? "AI Evaluation Complete"
                        : "AI Evaluation Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        completedAI == questions.length && questions.isNotEmpty
                            ? Icons.check_circle
                            : Icons.smart_toy,
                        color:
                            completedAI == questions.length &&
                                questions.isNotEmpty
                            ? Colors.green
                            : Colors.blue,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          completedAI == questions.length &&
                                  questions.isNotEmpty
                              ? "All ${questions.length} questions evaluated."
                              : "$completedAI / ${questions.length} Questions Completed",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  LinearProgressIndicator(
                    color:
                        completedAI == questions.length && questions.isNotEmpty
                        ? Colors.green
                        : Colors.blue,
                    value: questions.isEmpty
                        ? 0
                        : completedAI / questions.length,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    if (questions.isEmpty) ...[
                      const SizedBox(height: 80),

                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),

                            SizedBox(height: 20),

                            Text(
                              "Loading assessment...",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Generating question cards...",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: questions.length,

                      itemBuilder: (context, index) {
                        final question = questions[index];

                        final questionId = question['id'];

                        final answerKey =
                            "Q${question['question_number']}${question['sub_question'] ?? ''}";

                        answerControllers.putIfAbsent(
                          questionId,
                          () => TextEditingController(
                            text: widget.detectedAnswers[answerKey] ?? "",
                          ),
                        );

                        markControllers.putIfAbsent(
                          questionId,
                          () => TextEditingController(
                            text:
                                (aiMarks[questionId] ??
                                        estimatedMarks[questionId] ??
                                        0)
                                    .toString(),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),

                          child: buildAnswerField(
                            questionId,

                            question['sub_question'] == null
                                ? "Question ${question['question_number']} (${question['max_marks']} marks)"
                                : "Question ${question['question_number']}${question['sub_question']} (${question['max_marks']} marks)",

                            question['question_text'],

                            answerControllers[questionId]!,

                            estimatedMarks[questionId] ?? 0,

                            question['max_marks'],
                          ),
                        );
                      },
                    ),

                    if (questions.isNotEmpty)
                      SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: (isSaving || completedAI != questions.length)
                            ? null
                            : () async {
                                setState(() {
                                  isSaving = true;
                                });

                                try {
                                  int totalScore = 0;
                                  int totalMarks = 0;

                                  for (var question in questions) {
                                    final questionId = question['id'];

                                    final answer =
                                        answerControllers[questionId]!.text
                                            .toLowerCase();

                                    debugPrint("");
                                    debugPrint(
                                      "==============================",
                                    );
                                    debugPrint(
                                      "Question ${question['question_number']}${question['sub_question'] ?? ''}",
                                    );
                                    debugPrint("Student Answer:");
                                    debugPrint(answer);

                                    final keywords = await Supabase
                                        .instance
                                        .client
                                        .from('keywords')
                                        .select()
                                        .eq('question_id', questionId);

                                    final keywordList = keywords
                                        .map((k) => k['keyword'].toString())
                                        .toList();

                                    int matchedKeywords = 0;

                                    for (var keyword in keywords) {
                                      final keywordText = keyword['keyword']
                                          .toString()
                                          .toLowerCase();

                                      debugPrint("Keyword: $keywordText");

                                      if (answer.contains(keywordText)) {
                                        matchedKeywords++;

                                        debugPrint("✅ MATCHED");
                                      } else {
                                        debugPrint("❌ NOT MATCHED");
                                      }
                                    }

                                    final totalKeywords = keywords.length;

                                    debugPrint(
                                      "Matched Keywords = $matchedKeywords",
                                    );
                                    debugPrint(
                                      "Total Keywords = ${keywords.length}",
                                    );

                                    double marksAwarded = 0;

                                    debugPrint(
                                      "Awarded Marks = ${marksAwarded.round()}",
                                    );

                                    if (totalKeywords > 0) {
                                      marksAwarded =
                                          (matchedKeywords / totalKeywords) *
                                          question['max_marks'];
                                    }

                                    final aiResult =
                                        await GeminiService.verifyAnswer(
                                          question: question['question_text'],

                                          keywords: keywordList,

                                          studentAnswer:
                                              answerControllers[questionId]!
                                                  .text,

                                          maxMarks:
                                              (question['max_marks'] as num)
                                                  .toInt(),

                                          nlpMarks: marksAwarded.round(),
                                        );

                                    final finalMarks = teacherEdited[questionId] == true
                                        ? int.tryParse(markControllers[questionId]!.text) ??
                                        aiResult["marks"] as int
                                        : aiResult["marks"] as int;
                                    totalScore += finalMarks;
                                    totalMarks += (question['max_marks'] as num)
                                        .toInt();

                                    debugPrint(
                                      "INSERTING -> "
                                      "Submission: ${widget.submissionId} | "
                                      "QuestionID: $questionId | "
                                      "Answer: ${answerControllers[questionId]!.text} | "
                                      "Marks: $finalMarks",
                                    );

                                    await Supabase.instance.client
                                        .from('student_answers')
                                        .upsert(
                                          {
                                            'submission_id':
                                                widget.submissionId,
                                            'question_id': questionId,
                                            'detected_answer':
                                                answerControllers[questionId]!
                                                    .text,
                                            'marks_awarded': finalMarks,
                                            'ai_reason': aiResult["reason"],
                                            'ai_confidence':
                                                aiResult["confidence"],
                                          },
                                          onConflict:
                                              'submission_id,question_id',
                                        );
                                  }

                                  debugPrint("TOTAL MARKS = $totalMarks");
                                  debugPrint("TOTAL SCORE = $totalScore");

                                  double percentage = 0;

                                  if (totalMarks > 0) {
                                    percentage =
                                        (totalScore / totalMarks) * 100;
                                  }

                                  String grade = "F";
                                  String status = "Fail";

                                  if (percentage >= 80) {
                                    grade = "A";
                                    status = "Pass";
                                  } else if (percentage >= 70) {
                                    grade = "B";
                                    status = "Pass";
                                  } else if (percentage >= 60) {
                                    grade = "C";
                                    status = "Pass";
                                  } else if (percentage >= 50) {
                                    grade = "D";
                                    status = "Pass";
                                  }

                                  if (!context.mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentResultScreen(
                                        sessionId: widget.sessionId,

                                        studentName: widget.studentName,
                                        studentId: widget.studentId,

                                        submissionId: widget.submissionId,

                                        score: totalScore,
                                        totalMarks: totalMarks,

                                        grade: grade,
                                        percentage: percentage,
                                        status: status,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint(e.toString());
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isSaving = false;
                                    });
                                  }
                                }
                              },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyBlue,

                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                                completedAI == questions.length
                                    ? "Save and Grade"
                                    : "Waiting for AI... ($completedAI/${questions.length})",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnswerField(
    String questionId,
    String title,
    String questionText,
    TextEditingController controller,
    int estimatedMarks,
    int maxMarks,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text(
            questionText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: aiLoading[questionId] == true
                  ? Colors.blue.shade50
                  : (aiMarks[questionId] ?? 0) == maxMarks
                  ? Colors.green.shade50
                  : (aiMarks[questionId] ?? 0) == 0
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "AI Evaluation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    const Text(
                      "Marks",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const Spacer(),

                    aiLoading[questionId] == true
                        ? const Text(
                            "Updating...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        : Text(
                            "${aiMarks[questionId] ?? estimatedMarks} / $maxMarks",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),

                    if (aiLoading[questionId] != true) ...[
                      const SizedBox(width: 6),

                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),

                        onPressed: () async {
                          final result = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Edit Marks"),

                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Maximum Marks: $maxMarks"),

                                    const SizedBox(height: 15),

                                    TextField(
                                      controller: markControllers[questionId],
                                      keyboardType: TextInputType.number,

                                      decoration: const InputDecoration(
                                        labelText: "Marks Awarded",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Cancel"),
                                  ),

                                  ElevatedButton(
                                    onPressed: () {
                                      int? value = int.tryParse(
                                        markControllers[questionId]!.text,
                                      );

                                      if (value == null) return;

                                      if (value < 0) value = 0;

                                      if (value > maxMarks) value = maxMarks;

                                      Navigator.pop(context, value);
                                    },
                                    child: const Text("Save"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              aiMarks[questionId] = result;
                              markControllers[questionId]!.text = result
                                  .toString();

                              teacherEdited[questionId] = true;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),

                if (teacherEdited[questionId] == true) ...[
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.green),
                          SizedBox(width: 5),
                          Text(
                            "Teacher Final Mark",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text(
                      "Confidence",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    aiLoading[questionId] == true
                        ? const Text("Updating...")
                        : Text("${aiConfidence[questionId] ?? 0}%"),
                  ],
                ),

                const SizedBox(height: 15),

                if ((aiConfidence[questionId] ?? 0) == -1) ...[
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "AI Evaluation Failed",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(aiReasons[questionId] ?? "Unable to contact AI."),

                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        aiLoading[questionId] = true;
                      });

                      final keywords = await Supabase.instance.client
                          .from('keywords')
                          .select()
                          .eq('question_id', questionId);

                      await verifyQuestionAI(
                        {
                          'id': questionId,
                          'question_text': questionText,
                          'max_marks': maxMarks,
                        },
                        keywords,
                        controller.text,
                        estimatedMarks,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry AI"),
                  ),
                ] else ...[
                  const Text(
                    "Reason",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  aiLoading[questionId] == true
                      ? const Text(
                          "AI is evaluating the answer...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          aiReasons[questionId] ?? "No AI result available.",
                        ),
                ],
              ],
            ),
          ),

          const Divider(height: 30),

          const Text(
            "Detected Student Answer",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            maxLines: 4,

            textInputAction: TextInputAction.done,

            onEditingComplete: () async {
              FocusScope.of(context).unfocus();

              setState(() {
                aiLoading[questionId] = true;
              });

              final keywords = await Supabase.instance.client
                  .from('keywords')
                  .select()
                  .eq('question_id', questionId);

              await verifyQuestionAI(
                {
                  'id': questionId,
                  'question_text': questionText,
                  'max_marks': maxMarks,
                },
                keywords,
                controller.text.toLowerCase(),
                estimatedMarks,
              );
            },

            decoration: InputDecoration(
              hintText: "Review or edit the detected answer...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
