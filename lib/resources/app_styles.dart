import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用中使用的样式常量
class AppStyles {
  // 边框半径
  static final BorderRadius itemBorderRadius = BorderRadius.circular(12);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(16);

  // 文本样式
  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle subtitle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // 卡片样式
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: itemBorderRadius,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // 按钮样式
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: AppColors.success,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // 输入框样式
  static final InputDecoration searchInputDecoration = InputDecoration(
    hintText: '搜索...',
    filled: true,
    fillColor: Colors.grey.withOpacity(0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
