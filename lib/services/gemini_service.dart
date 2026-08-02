import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class GeminiService {

  static const String apiKey = "AQ.Ab8RN6K0zqkif8RJtS6vfFqwCGEN3KzcfGawdj9KNjFhx3iPqw";

  static Future<String> cleanQuestions(
      String ocrText,
      ) async {

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response =
    await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [
          {
            "parts": [
              {
                "text":
                """
You are helping a school marking system.

The OCR text may contain one or more pages of an examination paper.

The teacher may upload the pages in ANY order.

Your job is to reconstruct the paper using the ORIGINAL printed question numbers.

Rules:

- Detect every question.
- Detect subquestions (A), (B), (C), (D) if they exist.
- Detect the marks for each question if shown.
- Remove page headers.
- Remove page footers.
- Remove instructions.
- If the paper is MCQ, remove the answer options (A, B, C, D). If the paper contains subjective subquestions (A), (B), (C), (D), preserve them as subquestions.
- Remove answer lines.
- Keep ONLY the actual question text.
- If a question is printed in BOTH Malay and English, preserve BOTH languages.
- Keep the wording exactly as printed.
- Do NOT translate.
- Do NOT remove either language.
- Combine both languages into a single question text in the same order as the original paper.
- Keep the ORIGINAL printed question number.
- Ignore the order that the pages were uploaded.
- If Question 4 appears before Question 1, still return Question 1 first.

Return format:

Q1||Question text|2
Q2||Question text|4
Q3|A|Sub question text|3
Q3|B|Sub question text|2

Meaning:

Question Number | Sub Question | Question Text | Marks

If there is no sub question, leave it blank.

Examples:

Q1||What is listening?|2
Q2||Why do we listen?|4
Q3|A|Define communication.|2
Q3|B|State two examples.|3

Return ONLY the questions.

Do not explain.
Do not use markdown.
Do not use bullet points.

Example for bilingual questions:

Q1|A|Apakah yang diwakili oleh nombor 3? / What is represented by the number 3?|1

Q1|B|Nyatakan satu sifat fizikal unsur Z. / State one physical property of Z element.|1

OCR TEXT:

$ocrText
"""
              }
            ]
          }
        ]
      }),
    );

    print("STATUS = ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {

      final data =
      jsonDecode(response.body);

      return data["candidates"][0]
      ["content"]["parts"][0]
      ["text"];

    }

    return "ERROR";
  }

  static Future<String> cleanMcqQuestions(
      String ocrText,
      ) async {

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [
          {
            "parts": [
              {
                "text": """
You are helping an AI school marking system.

The OCR text may come from MULTIPLE uploaded pages.

The pages may NOT be uploaded in order.

Extract ALL multiple choice questions.

Rules:

- Keep the ORIGINAL question number.
- Ignore page order.
- Ignore instructions.
- Ignore page headers.
- Ignore page footers.
- Ignore answer choices (A, B, C, D).
- Detect the marks if available.
- If marks are missing, return 1.
- Return one line per question.

Return format:

Q1|Question text|2
Q2|Question text|1
Q3|Question text|5

Return ONLY these lines.

Do not explain.

OCR TEXT:

$ocrText
"""
              }
            ]
          }
        ]

      }),
    );

    print("MCQ STATUS = ${response.statusCode}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data["candidates"][0]
      ["content"]["parts"][0]
      ["text"];

    }

    return "ERROR";
  }

  static Future<String> extractStudentAnswers(
      String questionList,
      String ocrText,
      ) async {
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response =
    await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [
          {
            "parts": [
              {
                "text":
                """
                You are helping GradeLens, an AI school marking system.

The teacher has already uploaded the official examination paper.

Official Question List:

$questionList

The student has uploaded one or more answer sheet pages.

The OCR below may contain text from MULTIPLE pages.

The pages may NOT be uploaded in order.

The OCR may contain:

- page numbers
- page headers
- page footers
- duplicated text
- OCR mistakes
- continued answers across pages

Your task is to reconstruct the student's answers.

Rules:

- Match every answer with the OFFICIAL QUESTION LIST.
- Match answers using BOTH the question number and the question content if OCR mistakes occur.
- Always use the official question numbers.
- Ignore the order that the pages were uploaded.
- If Question 5 appears before Question 2, still return Question 2 first.
- If an answer continues onto another page, merge it into one answer.
- Never split one answer into two questions.
- Never merge two different questions together.
- Ignore page breaks completely.
- Ignore question paper text.
- Ignore instructions.
- Ignore page numbers.
- Ignore headers.
- Ignore footers.
- Ignore marks.
- Ignore duplicated OCR text.
- If OCR repeats the same sentence, keep only one copy.

IMPORTANT

You MUST return exactly one line for every question in the Official Question List.

If the student leaves a question blank, return:

Q2|

Do NOT omit blank questions.

The total number of returned answers MUST equal the total number of official questions.

Keep the exact question IDs provided.

Example:

Official Question List

Q1
Q2
Q2A
Q2B
Q3

Return

Q1|Answer

Q2|

Q2A|Answer

Q2B|

Q3|Answer

OCR TEXT:

$ocrText
"""
              }
            ]
          }
        ]
      }),
    );

    print("STATUS = ${response.statusCode}");
    print(response.body);

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      return data["candidates"][0]
      ["content"]["parts"][0]
      ["text"];
    }

    return "ERROR";
  }

  static Future<Map<String, String>> extractStudentInformation(
      String ocrText,
      ) async {

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [
          {
            "parts": [
              {
                "text": """
You are helping GradeLens, an AI school marking system.

The following text was extracted using OCR from the FRONT PAGE of a student's examination paper.

Extract ONLY the following information if available:

- Student Name
- Student ID
- Class

Rules:

- Ignore school name.
- Ignore subject.
- Ignore examination title.
- Ignore dates.
- Ignore teacher names.
- Ignore instructions.
- If a value is missing, leave it blank.

Return EXACTLY in this format:

NAME|Student Name
ID|Student ID
CLASS|Student Class

Example:

NAME|John Tan Wei Ming
ID|22DIT045
CLASS|5 Amanah

Return ONLY these three lines.

OCR TEXT:

$ocrText
"""
              }
            ]
          }
        ]

      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
      return {
        "name": "",
        "id": "",
        "class": "",
      };
    }

    final data = jsonDecode(response.body);

    String text =
    data["candidates"][0]["content"]["parts"][0]["text"];

    String name = "";
    String id = "";
    String studentClass = "";

    final lines = text.split('\n');

    for (final line in lines) {

      if (line.startsWith("NAME|")) {
        name = line.replaceFirst("NAME|", "").trim();
      }

      if (line.startsWith("ID|")) {
        id = line.replaceFirst("ID|", "").trim();
      }

      if (line.startsWith("CLASS|")) {
        studentClass = line.replaceFirst("CLASS|", "").trim();
      }

    }

    return {
      "name": name,
      "id": id,
      "class": studentClass,
    };
  }

  static Future<Map<String, String>> extractStudentInformationFromImage(
      String imagePath,
      ) async {

    final bytes = await File(imagePath).readAsBytes();

    final base64Image = base64Encode(bytes);

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [

              {
                "text": """
You are helping GradeLens.

Look at this FRONT PAGE of a student's examination paper.

Extract ONLY:

- Student Name
- Student Class
- Student ID (if present)

Ignore:

- School name
- Subject
- Marks
- Teachers
- Instructions
- Logos

Return EXACTLY:

NAME|...
ID|...
CLASS|...

If something is missing, leave it blank.

Return ONLY those three lines.
"""
              },

              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }

            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      print(response.body);

      return {
        "name": "",
        "id": "",
        "class": "",
      };
    }

    final data = jsonDecode(response.body);

    String text =
    data["candidates"][0]["content"]["parts"][0]["text"];

    print(text);

    String name = "";
    String id = "";
    String studentClass = "";

    final lines = text.split('\n');

    for (final line in lines) {

      if (line.startsWith("NAME|")) {
        name = line.replaceFirst("NAME|", "").trim();
      }

      if (line.startsWith("ID|")) {
        id = line.replaceFirst("ID|", "").trim();
      }

      if (line.startsWith("CLASS|")) {
        studentClass = line.replaceFirst("CLASS|", "").trim();
      }

    }

    return {
      "name": name,
      "id": id,
      "class": studentClass,
    };
  }

  static Future<List<String>> detectMcqAnswers(
      String base64Image,
      ) async {

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [

          {
            "parts": [

              {
                "text": """
You are reading a multiple-choice answer sheet.

The image contains ONLY the answer area.

Determine the selected answer for every question.

Rules:

- Only return A, B, C or D.
- If blank, return X.
- Ignore printed letters.
- Ignore question numbers.
- Ignore page borders.
- Ignore handwriting outside bubbles.

Return ONLY JSON.

Example:

{
"1":"B",
"2":"D",
"3":"A",
"4":"X"
}

Do not explain.
Do not use markdown.
"""
              },

              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }

            ]
          }

        ]

      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
      return [];
    }

    final data = jsonDecode(response.body);

    String text =
    data["candidates"][0]["content"]["parts"][0]["text"];

    print(text);

    text = text
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();

    final jsonMap = jsonDecode(text);

    List<String> answers = [];

    for (int i = 1; i <= jsonMap.length; i++) {
      answers.add(jsonMap["$i"] ?? "X");
    }

    return answers;
  }

  static Future<Map<String, dynamic>> verifyAnswer({

    required String question,

    required List<String> keywords,

    required String studentAnswer,

    required int maxMarks,

    required int nlpMarks,

  }) async {

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({

        "contents": [
          {
            "parts": [

              {
                "text": """
You are assisting GradeLens, an AI-assisted school marking system.

The teacher has already created the marking scheme.

Question:

$question

Maximum Marks:

$maxMarks

Teacher Keywords:

${keywords.join('\n')}

Student Answer:

$studentAnswer

NLP Suggested Marks:

$nlpMarks

Instructions:

The teacher's keywords are the official marking scheme.

Evaluate the student's answer using ONLY the teacher's keywords.

If the student uses different wording, synonyms, or equivalent scientific meaning, you may still award marks.

Do NOT invent new marking criteria.

The NLP Suggested Marks were calculated using exact keyword matching.

Use them as a reference only.

If the NLP score is correct, keep it.

If the NLP missed valid synonyms or equivalent scientific meaning, you may increase the marks.

If the NLP awarded too many marks, you may reduce them.

Never exceed the Maximum Marks.

Your final score must always be based on the teacher's keywords.

Do NOT award marks for concepts that are not represented by the teacher's keywords.

Return ONLY valid JSON.

Example:

{
  "marks": 2,
  "reason": "The student expressed both required concepts using equivalent wording.",
  "confidence": 98
}
"""
              }

            ]
          }
        ]

      }),
    );

    if (response.statusCode != 200) {
      return {
        "marks": nlpMarks,
        "reason": "Unable to contact AI.",
        "confidence": -1,
      };
    }

    final data = jsonDecode(response.body);

    String text =
    data["candidates"][0]["content"]["parts"][0]["text"];

    print("AI VERIFY:");
    print(text);

    text = text
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();

    try {
      final result = jsonDecode(text);

      return {
        "marks": result["marks"] ?? nlpMarks,
        "reason": result["reason"] ?? "",
        "confidence": result["confidence"] ?? 0,
      };
    } catch (e) {
      return {
        "marks": nlpMarks,
        "reason": "AI returned an invalid response.",
        "confidence": -1,
      };
    }

  }
}