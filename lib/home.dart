import 'package:flutter/material.dart';
import 'models/wifi_model.dart';
import 'utils/toast_util.dart';
import 'resources/app_colors.dart';
import 'resources/app_styles.dart';
import 'resources/app_icons.dart';
import 'main.dart'; // 导入main.dart以使用navigateToTab函数
import './settings.dart';
import 'package:wifi_iot/wifi_iot.dart'; // 导入WiFi管理包
import 'dart:async'; // 导入异步支持

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCracking = false;
  bool _isLocked = false;
  bool _isScanning = false; // 添加扫描状态跟踪

  // 初始化为空列表，在应用启动后自动扫描
  List<WiFiNetwork> _wifiList = [];

  CrackingStatus _crackingStatus = CrackingStatus(
    wifiName: "", // 初始为空，待扫描后设置
    dictionaryName: "common_passwords.txt",
    dictionarySize: "3.2MB",
    estimatedTime: "2小时30分钟",
    currentProgress: "第1582行/共10000行",
    progressPercent: 0.45,
  );

  @override
  void initState() {
    super.initState();
    // 初始化时检查WiFi权限
    _checkWifiPermissions();

    // 添加应用启动完成后的回调，自动扫描WiFi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanWifi();
    });
  }

  // 检查WiFi权限
  Future<void> _checkWifiPermissions() async {
    bool canGetWifiList = await WiFiForIoTPlugin.isEnabled();
    if (!canGetWifiList) {
      // 如果WiFi未启用，显示提示
      ToastUtil.show(context, "请开启WiFi以扫描网络", ToastType.warning);
    }
  }

  // 扫描附近WiFi
  Future<void> _scanWifi() async {
    if (_isScanning) {
      ToastUtil.show(context, "正在扫描中，请稍候...");
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // 不显示扫描提示，因为应用启动时会自动扫描
    if (_wifiList.isNotEmpty) {
      ToastUtil.show(context, "正在扫描附近WiFi...");
    }

    try {
      // 检查WiFi是否启用
      bool isEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!isEnabled) {
        ToastUtil.show(context, "请开启WiFi以扫描网络", ToastType.warning);
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // 由于wifi_iot没有直接的startScan方法，我们直接获取WiFi列表
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      // 将原生WiFi列表转换为我们自定义的数据格式
      List<WiFiNetwork> scannedNetworks = [];

      for (var network in networks) {
        // 过滤掉空名称的WiFi网络
        if (network.ssid == null || network.ssid!.trim().isEmpty) {
          continue;
        }

        // 获取加密类型
        String encryption = "Unknown";
        String capabilities = network.capabilities ?? "";

        if (capabilities.contains("WPA3")) {
          encryption = "WPA3";
        } else if (capabilities.contains("WPA2")) {
          encryption = "WPA2";
        } else if (capabilities.contains("WPA")) {
          encryption = "WPA";
        } else if (capabilities.contains("WEP")) {
          encryption = "WEP";
        } else if (capabilities == "[ESS]") {
          encryption = "Open";
        }

        // 计算信号强度百分比 (RSSI通常在-100到0之间，转换为0-100%)
        int level = network.level ?? -70; // 默认值，如果为null
        int signalStrength = 100 + (level * 100) ~/ 100;
        signalStrength = signalStrength.clamp(0, 100); // 确保在0-100范围内

        // 创建WiFi网络对象
        WiFiNetwork wifiNetwork = WiFiNetwork(
          name: network.ssid ?? "未知网络",
          encryption: encryption,
          signal: signalStrength,
          isSelected: _wifiList.isEmpty
              ? true
              : (network.ssid ?? "") == _crackingStatus.wifiName,
        );

        scannedNetworks.add(wifiNetwork);
      }

      // 更新状态
      setState(() {
        if (scannedNetworks.isNotEmpty) {
          _wifiList = scannedNetworks;

          // 如果当前没有选中的WiFi，则选中第一个
          bool hasSelected = _wifiList.any((wifi) => wifi.isSelected);
          if (!hasSelected && _wifiList.isNotEmpty) {
            _wifiList[0].isSelected = true;

            // 更新破解状态显示的WiFi名称
            _crackingStatus = CrackingStatus(
              wifiName: _wifiList[0].name,
              dictionaryName: _crackingStatus.dictionaryName,
              dictionarySize: _crackingStatus.dictionarySize,
              estimatedTime: _crackingStatus.estimatedTime,
              currentProgress: _crackingStatus.currentProgress,
              progressPercent: _crackingStatus.progressPercent,
            );
          }
        }
        _isScanning = false;
      });

      // 仅在手动扫描时显示完成提示
      if (_wifiList.isNotEmpty) {
        ToastUtil.show(
            context, "扫描完成，发现${_wifiList.length}个WiFi网络", ToastType.success);
      }
    } catch (e) {
      ToastUtil.show(context, "扫描失败: $e", ToastType.error);
      setState(() {
        _isScanning = false;
      });
    }
  }

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

  void _navigateToDictionary() {
    // 弹出吐司选择字典
    ToastUtil.show(context, "跳转到字典页面");
  }

  void _navigateToSettings(BuildContext context) {
    // 使用全局导航方法切换到设置页面
    navigateToTab(3); // 3是设置页面的索引
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
              onPressed: _isScanning ? null : _scanWifi,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(AppIcons.search),
              label: Text(_isScanning ? '扫描中...' : '扫描WiFi'),
              style: AppStyles.primaryButtonStyle,
            ),
            TextButton.icon(
              onPressed: () => _navigateToSettings(context),
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
    if (_wifiList.isEmpty) {
      // 如果没有WiFi，显示提示
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                AppIcons.router,
                size: 48,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '没有发现WiFi网络',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _scanWifi,
                icon: Icon(AppIcons.search),
                label: const Text('重新扫描'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(AppIcons.router, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '附近WiFi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Text(
                '${_wifiList.length}个网络',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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
