import 'package:flutter/material.dart';
import 'models/wifi_model.dart';
import 'utils/toast_util.dart';
import 'resources/app_colors.dart';
import 'resources/app_styles.dart';
import 'resources/app_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCracking = false;
  bool _isLocked = false;

  CrackingStatus _crackingStatus = CrackingStatus(
    wifiName: "HomeWiFi_5G",
    dictionaryName: "common_passwords.txt",
    dictionarySize: "3.2MB",
    estimatedTime: "2小时30分钟",
    currentProgress: "第1582行/共10000行",
    progressPercent: 0.45,
  );

  final List<WiFiNetwork> _wifiList = [
    WiFiNetwork(
      name: "HomeWiFi_5G",
      encryption: "WPA2",
      signal: 90,
      isSelected: true,
    ),
    WiFiNetwork(
      name: "Neighbor_Network",
      encryption: "WPA2",
      signal: 75,
    ),
    WiFiNetwork(
      name: "CoffeeShop_Free",
      encryption: "Open",
      signal: 40,
    ),
    WiFiNetwork(
      name: "Office_Secure",
      encryption: "WPA3",
      signal: 65,
    ),
  ];

  void _toggleCracking() {
    setState(() {
      _isCracking = !_isCracking;
      if (_isCracking) {
        _startCrackingSimulation();
      }
    });
    ToastUtil.show(context, _isCracking ? "开始破解..." : "已暂停破解");
  }

  void _startCrackingSimulation() {
    // 模拟破解进度
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isCracking) return;
      setState(() {
        _crackingStatus = CrackingStatus(
          wifiName: _crackingStatus.wifiName,
          dictionaryName: _crackingStatus.dictionaryName,
          dictionarySize: _crackingStatus.dictionarySize,
          progressPercent: _crackingStatus.progressPercent + 0.01,
          estimatedTime:
              _updateEstimatedTime(_crackingStatus.progressPercent + 0.01),
          currentProgress:
              _updateProgress(_crackingStatus.progressPercent + 0.01),
        );

        if (_crackingStatus.progressPercent >= 1.0) {
          _crackingStatus = CrackingStatus(
            wifiName: _crackingStatus.wifiName,
            dictionaryName: _crackingStatus.dictionaryName,
            dictionarySize: _crackingStatus.dictionarySize,
            progressPercent: 1.0,
            estimatedTime: "完成",
            currentProgress: "完成",
          );
          _isCracking = false;
          ToastUtil.show(context, "WiFi密码破解成功！", ToastType.success);
          return;
        }

        _startCrackingSimulation();
      });
    });
  }

  String _updateEstimatedTime(double progress) {
    // 更新预计时间
    int remainingMinutes = ((1.0 - progress) * 150).floor();
    if (remainingMinutes > 60) {
      int hours = remainingMinutes ~/ 60;
      int minutes = remainingMinutes % 60;
      return "$hours小时$minutes分钟";
    } else {
      return "$remainingMinutes分钟";
    }
  }

  String _updateProgress(double progress) {
    // 更新进度信息
    int total = 10000;
    int current = (total * progress).floor();
    return "第$current行/共$total行";
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
    ToastUtil.show(
      context,
      _isLocked ? "已锁定当前WiFi，无法切换" : "已解锁，可以切换WiFi",
    );
  }

  void _selectWifi(WiFiNetwork network) {
    if (_isLocked) {
      ToastUtil.show(context, "当前WiFi已锁定，请先解锁", ToastType.warning);
      return;
    }

    setState(() {
      for (var wifi in _wifiList) {
        wifi.isSelected = wifi.name == network.name;
      }

      _crackingStatus = CrackingStatus(
        wifiName: network.name,
        dictionaryName: _crackingStatus.dictionaryName,
        dictionarySize: _crackingStatus.dictionarySize,
        estimatedTime: "计算中...",
        currentProgress: "准备中...",
        progressPercent: 0.0,
      );
    });
    ToastUtil.show(context, "已选择WiFi: ${network.name}");
  }

  void _scanWifi() {
    ToastUtil.show(context, "正在扫描附近WiFi...");
    Future.delayed(const Duration(seconds: 2), () {
      ToastUtil.show(context, "扫描完成，发现4个WiFi网络");
    });
  }

  void _navigateToDictionary() {
    // 将在主屏幕中处理页面切换
    ToastUtil.show(context, "跳转到字典页面");
  }

  void _navigateToSettings() {
    // 将在主屏幕中处理页面切换
    ToastUtil.show(context, "跳转到设置页面");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.wifi, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Fluteer WiFi', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlPanel(),
            _buildCrackingStatus(),
            _buildWifiList(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _scanWifi,
              icon: Icon(AppIcons.search),
              label: const Text('扫描WiFi'),
              style: AppStyles.primaryButtonStyle,
            ),
            TextButton.icon(
              onPressed: _navigateToSettings,
              icon: Icon(AppIcons.settings),
              label: const Text('待机设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrackingStatus() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.key, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '破解控制',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _toggleLock,
                  icon: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: _isLocked ? AppColors.wpa2 : AppColors.gray,
                  ),
                  tooltip: _isLocked ? '解锁' : '锁定',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(
                                text: 'WiFi名称: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: _crackingStatus.wifiName),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isLocked)
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: AppColors.wpa2,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                              text: '当前字典: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: _crackingStatus.dictionaryName),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _crackingStatus.dictionarySize,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: '预计剩余时间: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: _crackingStatus.estimatedTime),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: '当前进度: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: _crackingStatus.currentProgress),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _crackingStatus.progressPercent,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${(_crackingStatus.progressPercent * 100).toInt()}% 已完成'),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleCracking,
                          icon: Icon(
                              _isCracking ? AppIcons.pause : AppIcons.play),
                          label: Text(_isCracking ? '暂停' : '开始'),
                          style: AppStyles.successButtonStyle,
                        ),
                        OutlinedButton.icon(
                          onPressed: _navigateToDictionary,
                          icon: Icon(AppIcons.book),
                          label: const Text('选择字典'),
                          style: AppStyles.outlineButtonStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(AppIcons.router, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                '附近WiFi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        ..._wifiList.map((wifi) => _buildWifiItem(wifi)).toList(),
      ],
    );
  }

  Widget _buildWifiItem(WiFiNetwork wifi) {
    return Card(
      elevation: 0,
      color:
          wifi.isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.itemBorderRadius,
        side: BorderSide(
          color: wifi.isSelected
              ? AppColors.primary
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _selectWifi(wifi),
        borderRadius: AppStyles.itemBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wifi.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getEncryptionColor(wifi.encryption)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wifi.encryption,
                        style: TextStyle(
                          color: _getEncryptionColor(wifi.encryption),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.signal,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text('${wifi.signal}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEncryptionColor(String encryption) {
    switch (encryption) {
      case 'WPA2':
        return AppColors.wpa2;
      case 'WPA3':
        return AppColors.wpa3;
      case 'Open':
        return AppColors.open;
      default:
        return Colors.grey;
    }
  }
}
