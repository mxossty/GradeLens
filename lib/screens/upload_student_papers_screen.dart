import 'package:flutter/material.dart';
import 'package:gradelens_new/screens/ocr_review_screen.dart';
import '../theme/app_colors.dart';
import 'mcq_review_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/omr_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gradelens_new/services/gemini_service.dart';

class UploadStudentPapersScreen extends StatefulWidget {
  final String sessionId;
  final String submissionId;
  final String studentName;
  final String studentId;
  final String className;
  final int studentCount;
  final String questionType;

  const UploadStudentPapersScreen({
    super.key,
    required this.sessionId,
    required this.submissionId,
    required this.studentName,
    required this.studentId,
    required this.className,
    required this.studentCount,
    required this.questionType,
  });

  @override
  State<UploadStudentPapersScreen> createState() =>
      _UploadStudentPapersScreenState();
}

class _UploadStudentPapersScreenState extends State<UploadStudentPapersScreen> {
  String extractedText = "";
  String extractedAnswers = "";
  Map<String, String> parsedAnswers = {};
  String? answerSheetPath;
  String? debugImagePath;
  List<String> detectedMcqAnswers = [];
  bool isLoading = false;
  bool uploadCompleted = false;
  Map<String, dynamic> aiResults = {};

  List<String> extractMcqAnswers(String text) {
    List<String> answers = [];

    final regex = RegExp(r'(\d+)\s*[:.)-]?\s*([ABCD])', caseSensitive: false);

    final matches = regex.allMatches(text);

    for (final match in matches) {
      final answer = match.group(2)?.toUpperCase();

      if (answer != null) {
        answers.add(answer);
      }
    }

    return answers;
  }

  Future<void> pickAndReadAnswerSheet() async {
    final picker = ImagePicker();

    final images = await picker.pickMultiImage();

    if (images.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    answerSheetPath = images.first.path;

    if (widget.questionType == "MCQ") {
      detectedMcqAnswers = await OMRDetector.analyzeImage(answerSheetPath!);

      debugImagePath = answerSheetPath!.replaceAll(".jpg", "_answer_sheet.jpg");

      debugPrint("DETECTED MCQ ANSWERS:");
      debugPrint(detectedMcqAnswers.toString());

      setState(() {
        isLoading = false;
        uploadCompleted = true;
      });

      return;
    }

    final textRecognizer = TextRecognizer();

    String fullText = "";

    for (final image in images) {
      final inputImage = InputImage.fromFilePath(image.path);

      final recognizedText = await textRecognizer.processImage(inputImage);

      fullText += recognizedText.text;
      fullText += "\n\n";

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            debugPrint("${element.text} -> ${element.boundingBox}");
          }
        }
      }
    }

    setState(() {
      extractedText = fullText;
    });

    final questions = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId)
        .order('question_number', ascending: true)
        .order('sub_question', ascending: true);

    String questionList = "";

    for (final q in questions) {
      final questionId = "Q${q['question_number']}${q['sub_question'] ?? ''}";

      questionList += "$questionId|${q['question_text']}\n";
    }

    debugPrint("QUESTION LIST:");
    debugPrint(questionList);

    extractedAnswers = await GeminiService.extractStudentAnswers(
      questionList,
      extractedText,
    );

    debugPrint("RAW GEMINI:");
    debugPrint(extractedAnswers);

    parsedAnswers.clear();

    for (final line in extractedAnswers.split('\n')) {
      if (!line.contains('|')) continue;

      final parts = line.split('|');

      if (parts.length < 2) continue;

      final questionId = parts.first.trim();

      final answer = parts.sublist(1).join('|').trim();

      parsedAnswers[questionId] = answer;
    }

    debugPrint("PARSED ANSWERS:");
    debugPrint(parsedAnswers.toString());
    debugPrint("LENGTH:");
    debugPrint(parsedAnswers.length.toString());

    debugPrint(parsedAnswers.toString());

    debugPrint("EXTRACTED STUDENT ANSWERS:");

    debugPrint(extractedAnswers);

    debugPrint("ANSWER OCR:");
    debugPrint(extractedText);

    await textRecognizer.close();

    // await prepareAIEvaluation();

    setState(() {
      isLoading = false;
      uploadCompleted = true;
    });
  }

  Future<void> evaluateQuestion(dynamic question) async {
    final questionId = question['id'];

    final answerKey =
        "Q${question['question_number']}${question['sub_question'] ?? ''}";

    final studentAnswer = parsedAnswers[answerKey] ?? "";

    final keywords = await Supabase.instance.client
        .from('keywords')
        .select()
        .eq('question_id', questionId);

    final keywordList = keywords.map((k) => k['keyword'].toString()).toList();

    int matchedKeywords = 0;

    for (final keyword in keywords) {
      if (studentAnswer.toLowerCase().contains(
        keyword['keyword'].toString().toLowerCase(),
      )) {
        matchedKeywords++;
      }
    }

    int estimated = 0;

    if (keywords.isNotEmpty) {
      estimated = ((matchedKeywords / keywords.length) * question['max_marks'])
          .round();
    }

    final result = await GeminiService.verifyAnswer(
      question: question['question_text'],
      keywords: keywordList,
      studentAnswer: studentAnswer,
      maxMarks: (question['max_marks'] as num).toInt(),
      nlpMarks: estimated,
    );

    aiResults[questionId] = result;
  }

  Future<void> prepareAIEvaluation() async {
    final questions = await Supabase.instance.client
        .from('questions')
        .select()
        .eq('session_id', widget.sessionId)
        .order('question_number', ascending: true)
        .order('sub_question', ascending: true);

    aiResults.clear();

    const batchSize = 5;

    for (int i = 0; i < questions.length; i += batchSize) {
      final batch = questions.skip(i).take(batchSize);

      await Future.wait(batch.map((question) => evaluateQuestion(question)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      child: Scaffold(
        backgroundColor: AppColors.cream,

        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.navyBlue,
          title: const Text(
            "Upload Student Papers",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: (uploadCompleted || isLoading)
                        ? null
                        : () async {
                            await pickAndReadAnswerSheet();
                          },

                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.navyBlue, width: 2),
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          if (isLoading) ...[
                            const CircularProgressIndicator(),

                            const SizedBox(height: 20),

                            const Text(
                              "Processing Answer Sheet...",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "OCR and AI are extracting the student's answers...",
                            ),
                          ] else if (uploadCompleted) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 70,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Answer Sheet Processed",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Ready to Continue",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.description,
                              size: 70,
                              color: AppColors.navyBlue,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Upload Answer Sheets",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Student papers / PDF",
                              style: TextStyle(color: AppColors.textGrey),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "For accurate detection, ensure the entire paper and all four corners are visible.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: Text("${widget.studentCount} Students"),
                          subtitle: Text("Class: ${widget.className}"),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (widget.questionType == "MCQ") {
                                if (answerSheetPath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please upload an answer sheet first.",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                debugPrint("DETECTED ANSWERS:");
                                debugPrint(detectedMcqAnswers.toString());

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MCQReviewScreen(
                                      submissionId: widget.submissionId,
                                      sessionId: widget.sessionId,
                                      className: widget.className,
                                      subject: "",
                                      detectedText: extractedText,
                                      answerSheetPath:
                                          debugImagePath ?? answerSheetPath!,

                                      detectedAnswers: detectedMcqAnswers,

                                      studentId: widget.studentId,
                                      studentName: widget.studentName,
                                    ),
                                  ),
                                );
                              } else {
                                if (extractedText.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please upload an answer sheet first.",
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OCRReviewScreen(
                                      className: widget.className,
                                      sessionId: widget.sessionId,
                                      submissionId: widget.submissionId,
                                      studentName: widget.studentName,
                                      studentId: widget.studentId,
                                      detectedAnswers: parsedAnswers,
                                      aiResults: aiResults,
                                    ),
                                  ),
                                );
                              }
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,

                        padding: EdgeInsets.symmetric(vertical: 18),
                      ),

                      child: const Text(
                        "Start Checking",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.45),

                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      CircularProgressIndicator(color: Colors.white),

                      SizedBox(height: 25),

                      Text(
                        "Extracting Answer Sheet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "OCR and AI are analysing the student's paper.\nPlease wait...",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
}
