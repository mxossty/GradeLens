import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'add_keywords_screen.dart';
import 'mcq_answers_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class UploadPaperScreen extends StatefulWidget {
  final String className;
  final String sessionId;
  final String subject;
  final String questionType;
  final DateTime assessmentDate;
  final int studentCount;
  final int mcqQuestionCount;

  const UploadPaperScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.questionType,
    required this.assessmentDate,
    required this.sessionId,
    required this.studentCount,
    required this.mcqQuestionCount,
  });

  @override
  State<UploadPaperScreen> createState() => _UploadPaperScreenState();
}

class _UploadPaperScreenState extends State<UploadPaperScreen> {
  List<XFile> selectedImages = [];

  String extractedText = "";
  List<String> extractedQuestions = [];
  List<Map<String, dynamic>> extractedMcqQuestions = [];
  String geminiQuestions = "";
  bool isLoading = false;
  bool uploadCompleted = false;
  bool isSaving = false;

  Future<void> pickAndReadImage() async {
    try {
      void extractMcqQuestions() {
        List<Map<String, dynamic>> questions = [];

        final lines = geminiQuestions.split('\n');

        for (String line in lines) {
          if (!line.contains('|')) continue;

          final parts = line.split('|');

          if (parts.length < 3) continue;

          final questionNumber =
              int.tryParse(parts[0].replaceAll('Q', '').trim()) ?? 0;

          final questionText = parts[1].trim();

          final marks = int.tryParse(parts[2].trim()) ?? 1;

          questions.add({
            'question_number': questionNumber,

            'text': questionText,

            'marks': marks,
          });
        }

        questions.sort(
              (a, b) => a['question_number'].compareTo(b['question_number']),
        );

        setState(() {
          extractedMcqQuestions = questions;
        });

        debugPrint("===== MCQ GEMINI =====");

        for (var q in extractedMcqQuestions) {
          debugPrint(q.toString());
        }
      }

      void extractQuestions() {
        final regex = RegExp(r'^(Q\.\d+|\d+\.?|\d+\))', multiLine: true);

        final matches = regex.allMatches(extractedText);

        List<String> questions = [];

        for (int i = 0; i < matches.length; i++) {
          final start = matches.elementAt(i).start;

          final end = i < matches.length - 1
              ? matches.elementAt(i + 1).start
              : extractedText.length;

          final question = extractedText.substring(start, end).trim();

          questions.add(question);
        }

        setState(() {
          extractedQuestions = questions;
        });

        for (var q in extractedQuestions) {
          debugPrint("==========");
          debugPrint(q);
        }
      }

      final picker = ImagePicker();

      final images = await picker.pickMultiImage();

      if (images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one question paper."),
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
        selectedImages = images;
      });

      final textRecognizer = TextRecognizer();

      String fullText = "";

      for (final image in selectedImages) {
        final inputImage = InputImage.fromFilePath(image.path);

        final recognizedText = await textRecognizer.processImage(inputImage);

        fullText += recognizedText.text;
        fullText += "\n\n";
      }

      setState(() {
        extractedText = fullText;
      });

      await textRecognizer.close();

      debugPrint("OCR FINISHED");
      debugPrint(extractedText);

      debugPrint("CALLING GEMINI...");
      debugPrint("GEMINI FINISHED");

      if (widget.questionType == "MCQ") {
        geminiQuestions = await GeminiService.cleanMcqQuestions(extractedText);

        if (geminiQuestions.trim().isEmpty || geminiQuestions == "ERROR") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Failed to process question paper. Please try again.",
              ),
            ),
          );

          return;
        }

        debugPrint("MCQ GEMINI:");
        debugPrint(geminiQuestions);

        extractMcqQuestions();

        if (extractedMcqQuestions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No questions were detected. Please upload a clearer question paper.",
              ),
            ),
          );

          return;
        }
      } else {
        geminiQuestions = await GeminiService.cleanQuestions(extractedText);

        if (geminiQuestions.trim().isEmpty || geminiQuestions == "ERROR") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Failed to process question paper. Please try again.",
              ),
            ),
          );

          return;
        }

        debugPrint("SUBJECTIVE GEMINI:");
        debugPrint(geminiQuestions);

        extractQuestions();
        if (extractedQuestions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No questions were detected. Please upload a clearer question paper.",
              ),
            ),
          );

          return;
        }
      }

      for (var q in extractedQuestions) {
        debugPrint("QUESTION:");
        debugPrint(q);
      }

      debugPrint("FULL OCR:");
      debugPrint(extractedText);

      debugPrint(extractedText);

      if (mounted) {
        setState(() {
          uploadCompleted = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This session has already been created. Edit it later from My Sessions.",
            ),
          ),
        );
      },

      child: Scaffold(
        backgroundColor: AppColors.cream,

        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.navyBlue,
          title: const Text(
            "Upload Paper",
            style: TextStyle(color: Colors.white),
          ),
        ),

        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: (uploadCompleted || isLoading)
                        ? null
                        : () async {
                      await pickAndReadImage();
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
                              "Processing Question Paper...",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text("Please wait..."),
                          ] else if (uploadCompleted) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 70,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Question Paper Processed",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text("${selectedImages.length} page(s) uploaded"),


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
                              Icons.cloud_upload,
                              size: 70,
                              color: AppColors.navyBlue,
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "Upload Question Paper",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Teacher Question Sheet",
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Session Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text("Class: ${widget.className}"),

                        Text("Subject: ${widget.subject}"),

                        Text("Students: ${widget.studentCount}"),

                        Text("Type: ${widget.questionType}"),

                        Text(
                          "Date: ${widget.assessmentDate.day}/${widget.assessmentDate.month}/${widget.assessmentDate.year}",
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,

                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),

                      onPressed: (isSaving || isLoading)
                          ? null
                          : () async {
                        setState(() {
                          isSaving = true;
                        });

                        try {
                          final existingQuestions = await Supabase
                              .instance
                              .client
                              .from('questions')
                              .select('id')
                              .eq('session_id', widget.sessionId);

                          if (widget.questionType == "MCQ" &&
                              existingQuestions.isEmpty) {
                            debugPrint(
                              "QUESTION COUNT: ${extractedMcqQuestions.length}",
                            );

                            if (extractedMcqQuestions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please upload a question paper first.",
                                  ),
                                ),
                              );

                              return;
                            }

                            for (
                            int i = 0;
                            i < extractedMcqQuestions.length;
                            i++
                            ) {
                              await Supabase.instance.client
                                  .from('questions')
                                  .insert({
                                'session_id': widget.sessionId,
                                'question_number':
                                extractedMcqQuestions[i]['question_number'],
                                'question_text':
                                extractedMcqQuestions[i]['text'],
                                'max_marks':
                                extractedMcqQuestions[i]['marks'],
                              });
                            }
                          }

                          if (widget.questionType == "Subjective" &&
                              existingQuestions.isEmpty) {
                            if (geminiQuestions.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please upload a paper first.",
                                  ),
                                ),
                              );

                              return;
                            }

                            List<Map<String, dynamic>> parsedQuestions =
                            [];

                            final lines = geminiQuestions.split('\n');

                            for (String line in lines) {
                              if (!line.contains('|')) continue;

                              final parts = line.split('|');

                              if (parts.length < 4) continue;

                              parsedQuestions.add({
                                'question_number':
                                int.tryParse(
                                  parts[0].replaceAll('Q', ''),
                                ) ??
                                    0,
                                'sub_question': parts[1].trim(),
                                'question_text': parts[2].trim(),
                                'max_marks': int.tryParse(parts[3]) ?? 1,
                              });
                            }

                            parsedQuestions.sort((a, b) {
                              if (a['question_number'] !=
                                  b['question_number']) {
                                return a['question_number'].compareTo(
                                  b['question_number'],
                                );
                              }

                              return (a['sub_question'] ?? '').compareTo(
                                b['sub_question'] ?? '',
                              );
                            });

                            for (final question in parsedQuestions) {
                              debugPrint(
                                "${question['question_number']}"
                                    "${question['sub_question']} "
                                    "${question['question_text']}",
                              );

                              await Supabase.instance.client
                                  .from('questions')
                                  .insert({
                                'session_id': widget.sessionId,
                                'question_number':
                                question['question_number'],
                                'sub_question':
                                question['sub_question'],
                                'question_text':
                                question['question_text'],
                                'max_marks': question['max_marks'],
                              });
                            }
                          }

                          if (widget.questionType == "MCQ") {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => McqAnswersScreen(
                                  sessionId: widget.sessionId,
                                  className: widget.className,
                                  subject: widget.subject,
                                  questionType: widget.questionType,
                                  studentCount: widget.studentCount,
                                ),
                              ),
                            );

                          } else {

                            final reset = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddKeywordsScreen(
                                  sessionId: widget.sessionId,
                                  className: widget.className,
                                  subject: widget.subject,
                                  questionType: widget.questionType,
                                  studentCount: widget.studentCount,
                                ),
                              ),
                            );

                            if (reset == true) {

                              setState(() {
                                uploadCompleted = false;
                                selectedImages.clear();
                                extractedQuestions.clear();
                                extractedMcqQuestions.clear();
                                extractedText = "";
                                geminiQuestions = "";
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Previous questions removed. Please upload the new question paper.",
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );

                            }

                          }
                        } catch (e) {
                          print(e);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Something went wrong. Please try again.",
                              ),
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
                        uploadCompleted ? "Review Questions" : "Upload",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
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
                        "Extracting Question Paper",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "OCR and AI are analysing your pages.\nPlease wait...",
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