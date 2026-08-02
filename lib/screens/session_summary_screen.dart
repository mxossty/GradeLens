import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'class_screen.dart';

class SessionSummaryScreen extends StatelessWidget {

  final String className;
  final String subject;
  final String questionType;
  final int studentCount;

  const SessionSummaryScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.questionType,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor:
        AppColors.navyBlue,

        title: const Text(
          "Session Summary",
          style: TextStyle(
            color: Colors.white,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Review Session",
              style: TextStyle(
                fontSize:28,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height:25),

            summaryTile(
              Icons.class_,
              "Class",
              className,
            ),

            const SizedBox(height:15),

            summaryTile(
              Icons.menu_book,
              "Subject",
              subject,
            ),

            const SizedBox(height:15),

            summaryTile(
              Icons.people,
              "Students",
              studentCount.toString(),
            ),

            const SizedBox(height:15),

            summaryTile(
              Icons.quiz,
              "Question Type",
              questionType,
            ),

            const SizedBox(height:15),

            summaryTile(
              Icons.check,
              "Model Answers",
              "Added ✅",
            ),

            Spacer(),

            SizedBox(
              width:double.infinity,

              child: ElevatedButton(

                onPressed:(){

                  Navigator.pushAndRemoveUntil(
                    context,

                    MaterialPageRoute(
                      builder: (_)=>
                      const ClassScreen(),
                    ),

                        (route)=>false,
                  );

                },

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.navyBlue,

                  padding:
                  const EdgeInsets.symmetric(
                    vertical:18,
                  ),
                ),

                child: const Text(
                  "Save Session",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize:18,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget summaryTile(
      IconData icon,
      String title,
      String value){

    return Container(
      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
            20),
      ),

      child: ListTile(

        leading: Icon(
          icon,
          color:
          AppColors.navyBlue,
        ),

        title: Text(title),

        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }
}