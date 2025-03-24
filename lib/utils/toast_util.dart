import 'package:flutter/material.dart';

enum ToastType {
  info,
  success,
  error,
  warning,
}

class ToastUtil {
  static void show(BuildContext context, String message,
      [ToastType type = ToastType.info]) {
    Color backgroundColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = const Color(0xFF34C759);
        break;
      case ToastType.error:
        backgroundColor = const Color(0xFFFF3B30);
        break;
      case ToastType.warning:
        backgroundColor = const Color(0xFFFF9500);
        break;
      default:
        backgroundColor = const Color(0xFF007AFF);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
