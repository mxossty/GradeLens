import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'student_verification_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

class FrontPageCaptureScreen extends StatefulWidget {
  final String sessionId;

  const FrontPageCaptureScreen({super.key, required this.sessionId});

  @override
  State<FrontPageCaptureScreen> createState() => _FrontPageCaptureScreenState();
}

class _FrontPageCaptureScreenState extends State<FrontPageCaptureScreen> {
  bool isLoading = false;
  bool uploadCompleted = false;
  String detectedName = "";
  String detectedId = "";
  String detectedClass = "";

  Future<void> captureAndReadFrontPage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    if (image == null) {
      setState(() {
        isLoading = false;
      });

      return;
    }

    final studentInfo = await GeminiService.extractStudentInformationFromImage(
      image.path,
    );

    if (studentInfo["name"]!.isEmpty &&
        studentInfo["class"]!.isEmpty) {

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to detect student information. Please try another photo.",
          ),
        ),
      );

      return;
    }

    detectedName = studentInfo["name"] ?? "";

    detectedId = studentInfo["id"] ?? "";

    detectedClass = studentInfo["class"] ?? "";

    debugPrint(studentInfo.toString());

    setState(() {
      isLoading = false;
      uploadCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          "Capture Front Page",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            GestureDetector(
              onTap: uploadCompleted
                  ? null
                  : () async {
                      await captureAndReadFrontPage();
                    },

              child: Container(
                height: 280,
                width: double.infinity,

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
                        "Processing Front Page...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "AI is extracting the student's information...",
                      )
                    ]

                    else if (uploadCompleted) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 70,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Front Page Processed",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        detectedName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(detectedClass),

                      const SizedBox(height: 10),

                      const Text(
                        "Ready to Continue",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]

                    else ...[
                        Icon(
                          Icons.camera_alt,
                          size: 70,
                          color: AppColors.navyBlue,
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Capture Student Front Page",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Student details page",
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Take a photo of the front page containing the student's name and class.",
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,

                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),

                  onPressed: isLoading
                      ? null
                      : () async {
                    if (!uploadCompleted) {
                      await captureAndReadFrontPage();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentVerificationScreen(
                            sessionId: widget.sessionId,
                            detectedName: detectedName,
                            detectedId: detectedId,
                            detectedClass: detectedClass,
                          ),
                        ),
                      );
                    }
                  },

                child: Text(
                  uploadCompleted ? "Continue" : "Capture Front Page",
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
    );
  }
}
