import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Widget actionButton(
    IconData icon,
    String text, {
      VoidCallback? onTap,
    }) {
  return GestureDetector(
    onTap: onTap,

    child: Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          )
        ],
      ),

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 28,
            color: AppColors.navyBlue,
          ),

          const SizedBox(height:10),

          Text(
            text,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}