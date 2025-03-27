import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../resources/app_images.dart';

/// 可复用的应用Logo组件
///
/// 支持根据不同的屏幕尺寸自动调整大小
/// 可以通过size参数手动指定尺寸
class AppLogo extends StatelessWidget {
  /// 创建应用Logo
  ///
  /// [size] 指定Logo尺寸，如果为null，将根据屏幕尺寸自动调整
  /// [showGlow] 是否显示发光效果
  final double? size;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // 根据屏幕宽度计算合适的Logo尺寸
    final calculatedSize = size ?? _getAdaptiveLogoSize(screenWidth);

    return Container(
      width: calculatedSize,
      height: calculatedSize,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue
                      .withValues(red: 33, green: 150, blue: 243, alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            )
          : null,
      child: SvgPicture.asset(
        AppImages.wifiLogo,
        width: calculatedSize,
        height: calculatedSize,
      ),
    );
  }

  /// 根据屏幕宽度计算适应性Logo尺寸
  double _getAdaptiveLogoSize(double screenWidth) {
    if (screenWidth < 360) {
      return 80; // 小尺寸设备
    } else if (screenWidth < 400) {
      return 100; // 中等尺寸设备
    } else if (screenWidth < 600) {
      return 120; // 大尺寸手机
    } else {
      return 150; // 平板或大屏设备
    }
  }
}
