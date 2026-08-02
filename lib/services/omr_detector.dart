import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'dart:convert';
import '../services/gemini_service.dart';

class OMRDetector {
  static Future<List<String>> analyzeImage(String imagePath) async {
    debugPrint("========== OMR START ==========");

    final image = cv.imread(imagePath);
    final originalImage = image.clone();

    debugPrint("Image loaded!");

    final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

    debugPrint("Converted to grayscale.");

    final thresh = cv.adaptiveThreshold(
      gray,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY_INV,
      31,
      10,
    );

    debugPrint("Threshold complete.");

    cv.imwrite(imagePath.replaceAll(".jpg", "_threshold.jpg"), thresh);

    final contours = cv.findContours(
      thresh,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    debugPrint("Contours found: ${contours.$1.length}");

    double biggestArea = 0;
    int biggestIndex = -1;

    for (int i = 0; i < contours.$1.length; i++) {
      final area = cv.contourArea(contours.$1[i]);

      if (area > biggestArea) {
        biggestArea = area;
        biggestIndex = i;
      }
    }

    debugPrint("Largest contour area: $biggestArea");
    debugPrint("Largest contour index: $biggestIndex");
    //figure out which one of the countour it the answer sheet

    cv.drawContours(
      image,
      contours.$1,
      biggestIndex,
      cv.Scalar(0, 0, 255),
      thickness: 8,
    );

    debugPrint(imagePath.replaceAll(".jpg", "_largest.jpg"));

    final debugImage = imagePath.replaceAll(".jpg", "_largest.jpg");

    debugPrint(debugImage);

    final paperContour = contours.$1[biggestIndex];

    final perimeter = cv.arcLength(
      paperContour,
      true,
    );

    final paperShape = cv.approxPolyDP(
      paperContour,
      perimeter * 0.02,
      true,
    );

    debugPrint(paperShape.runtimeType.toString());

    final corners = List.from(paperShape);

    // Top Left
    corners.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final topLeft = corners.first;

    // Bottom Right
    final bottomRight = corners.last;

    // Top Right
    corners.sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
    final topRight = corners.first;

    // Bottom Left
    final bottomLeft = corners.last;

    final orderedCorners = [topLeft, topRight, bottomRight, bottomLeft];

    debugPrint("Paper has ${paperShape.length} corners");


    for (int i = 0; i < orderedCorners.length; i++) {
      debugPrint("Corner $i : ${orderedCorners[i]}");
    }

    debugPrint("Saving image with contour...");

    debugPrint(
        "TopLeft x type: ${orderedCorners[0].x.runtimeType}");
    debugPrint(
        "TopLeft y type: ${orderedCorners[0].y.runtimeType}");

    final srcPoints = cv.VecPoint.fromList([
      cv.Point(
        orderedCorners[0].x,
        orderedCorners[0].y,
      ),
      cv.Point(
        orderedCorners[1].x,
        orderedCorners[1].y,
      ),
      cv.Point(
        orderedCorners[2].x,
        orderedCorners[2].y,
      ),
      cv.Point(
        orderedCorners[3].x,
        orderedCorners[3].y,
      ),
    ]);

    final dstPoints = cv.VecPoint.fromList([
      cv.Point(0, 0),
      cv.Point(800, 0),
      cv.Point(800, 1200),
      cv.Point(0, 1200),
    ]);

    final matrix = cv.getPerspectiveTransform(
      srcPoints,
      dstPoints,
    );

    final warped = cv.warpPerspective(
      originalImage,
      matrix,
      (800, 1200),
    );

    final answerArea = cv.Rect(
      325,   // move right
      225,   // move down
      425,   // lower = narrower
      940,   // higher = taller
    );

    final answerSheet = warped.region(answerArea);

    cv.imwrite(
      imagePath.replaceAll(".jpg", "_warped.jpg"),
      warped,
    );

    final warpedGray = cv.cvtColor(
      answerSheet,
      cv.COLOR_BGR2GRAY,
    );

    final warpedThresh = cv.adaptiveThreshold(
      warpedGray,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY_INV,
      31,
      10,
    );

    cv.imwrite(
      imagePath.replaceAll(".jpg", "_warped_threshold.jpg"),
      warpedThresh,
    );

    final bubbleContours = cv.findContours(
      warpedThresh,
      cv.RETR_LIST,
      cv.CHAIN_APPROX_SIMPLE,
    );

    debugPrint(
        "Bubble contours: ${bubbleContours.$1.length}");

    final bubbleCandidates = [];

    for (final contour in bubbleContours.$1) {

      final area = cv.contourArea(contour);

      if (area < 20 || area > 3000) {
        continue;
      }

      final rect = cv.boundingRect(contour);

      if (rect.x < 200) {
        continue;
      }

      if (rect.x > 320 && rect.x < 360) {
        continue;
      }

      final ratio = rect.width / rect.height;

      if (ratio < 0.8 || ratio > 1.2) {
        continue;
      }

      bubbleCandidates.add(contour);
    }

    bubbleCandidates.sort((a, b) {
      final rectA = cv.boundingRect(a);
      final rectB = cv.boundingRect(b);

      return rectA.y.compareTo(rectB.y);
    });

    for (int i = 0; i < bubbleCandidates.length; i++) {
      final rect = cv.boundingRect(bubbleCandidates[i]);

      debugPrint(
        "Bubble $i -> x=${rect.x}, y=${rect.y}",
      );
    }

    debugPrint(
        "Bubble candidates: ${bubbleCandidates.length}");

    for (final contour in bubbleCandidates) {

      final rect = cv.boundingRect(contour);

      cv.rectangle(
        answerSheet,
        rect,
        cv.Scalar(0, 255, 0),
        thickness: 2,
      );
    }

    cv.imwrite(
      imagePath.replaceAll(".jpg", "_answer_sheet.jpg"),
      answerSheet,
    );

    final answerImagePath =
    imagePath.replaceAll(".jpg", "_answer_sheet.jpg");

    final imageBytes =
    File(answerImagePath).readAsBytesSync();

    final base64Image =
    base64Encode(imageBytes);

    final answers =
    await GeminiService.detectMcqAnswers(
      base64Image,
    );

    debugPrint("GEMINI MCQ ANSWERS:");
    debugPrint(answers.toString());

    debugPrint(
      imagePath.replaceAll(".jpg", "_bubble_candidates.jpg"),
    );

    debugPrint(
      imagePath.replaceAll(".jpg", "_warped.jpg"),
    );

    cv.imwrite(debugImage, image);

    return answers;

  }
}
