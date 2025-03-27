import 'package:flutter/material.dart';

/// 应用中使用的颜色常量
class AppColors {
  // 主题颜色
  static const Color primary = Color(0xFF0081FF);
  static const Color secondary = Color(0xFF30C88D);
  static const Color scaffoldBackground = Color(0xFFF9FAFF);

  // 状态颜色
  static const Color success = Color(0xFF30C88D);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4842);
  static const Color info = Color(0xFF33C4FF);

  // 灰度颜色
  static const Color gray = Color(0xFF9CA3AF);
  static const Color grayLight = Color(0xFFD1D5DB);
  static const Color grayDark = Color(0xFF4B5563);

  // 卡片颜色
  static Color cardBackground = Colors.white;
  static Color cardShadow =
      Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.05);

  // 文本颜色
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // 加密类型颜色
  static const Color wpa2 = Color(0xFFFF9500);
  static const Color wpa3 = Color(0xFF5856D6);
  static const Color open = Color(0xFF34C759);
}
