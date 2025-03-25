import 'package:flutter/material.dart';
import 'models/wifi_model.dart';
import 'utils/toast_util.dart';
import 'utils/file_util.dart'; // 添加FileUtil导入
import 'utils/wifi_util.dart'; // 添加WiFiUtil导入
import 'resources/app_colors.dart';
import 'resources/app_styles.dart';
import 'resources/app_icons.dart';
import 'main.dart'; // 导入main.dart以使用navigateToTab函数
import './settings.dart';
import 'package:wifi_iot/wifi_iot.dart'; // 导入WiFi管理包
import 'dart:async'; // 导入异步支持
import 'dart:io'; // 导入文件相关包
import 'dart:convert'; // 导入JSON相关包

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isCracking = false;
  bool _isLocked = false;
  bool _isScanning = false; // 添加扫描状态跟踪
  bool _hasSelectedWifi = false; // 添加是否有选中WiFi的状态

  // 初始化为空列表，在应用启动后自动扫描
  List<WiFiNetwork> _wifiList = [];

  // 定时器，用于定期更新WiFi信号强度
  Timer? _signalUpdateTimer;

  CrackingStatus _crackingStatus = CrackingStatus(
    wifiName: "", // 初始为空，待扫描后设置
    dictionaryName: "passwords.txt", // 默认使用passwords.txt字典
    dictionarySize: "待加载",
    estimatedTime: "未开始",
    currentProgress: "未开始",
    progressPercent: 0.0,
  );

  @override
  void initState() {
    super.initState();
    // 初始化时检查WiFi权限
    _checkWifiPermissions();

    // 添加应用启动完成后的回调，自动扫描WiFi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanWifi();
      _initDefaultDictionary();
      // 启动定时器，每5秒更新一次WiFi信号强度
      _startSignalUpdateTimer();
    });
  }

  @override
  void dispose() {
    // 取消定时器
    _signalUpdateTimer?.cancel();
    super.dispose();
  }

  // 启动WiFi信号强度更新定时器
  void _startSignalUpdateTimer() {
    _signalUpdateTimer?.cancel();
    _signalUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateWifiSignalStrength();
    });
  }

  // 更新WiFi信号强度
  Future<void> _updateWifiSignalStrength() async {
    if (_wifiList.isEmpty || _isScanning) {
      return; // 如果列表为空或者正在扫描，不更新
    }

    try {
      // 获取最新的WiFi列表
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      // 更新现有WiFi列表的信号强度
      setState(() {
        for (var wifi in _wifiList) {
          // 在新获取的网络列表中查找匹配的网络
          for (var network in networks) {
            if (network.ssid == wifi.name) {
              // 更新信号强度
              int level = network.level ?? -70; // 默认值，如果为null
              int signalStrength = 100 + (level * 100) ~/ 100;
              signalStrength = signalStrength.clamp(0, 100); // 确保在0-100范围内
              wifi.signal = signalStrength;
              break;
            }
          }
        }
      });
    } catch (e) {
      print('更新WiFi信号强度失败: $e');
    }
  }

  // 初始化默认字典
  Future<void> _initDefaultDictionary() async {
    try {
      final dictionaryPath = await FileUtil.getDictionaryPath();
      final defaultDictFile = File('$dictionaryPath/passwords.txt');

      if (await defaultDictFile.exists()) {
        final fileSize = await defaultDictFile.length();
        String sizeDisplay;
        if (fileSize < 1024 * 1024) {
          sizeDisplay = '${(fileSize / 1024).toStringAsFixed(1)}KB';
        } else {
          sizeDisplay = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
        }

        setState(() {
          _crackingStatus = CrackingStatus(
            wifiName: _crackingStatus.wifiName,
            dictionaryName: "passwords.txt",
            dictionarySize: sizeDisplay,
            estimatedTime: "未开始",
            currentProgress: "未开始",
            progressPercent: 0.0,
          );
        });
      }
    } catch (e) {
      print('初始化默认字典失败: $e');
    }
  }

  // 检查WiFi权限
  Future<void> _checkWifiPermissions() async {
    bool canGetWifiList = await WiFiForIoTPlugin.isEnabled();
    if (!canGetWifiList) {
      // 如果WiFi未启用，显示提示
      ToastUtil.show(context, "请开启WiFi以扫描网络", ToastType.warning);
    }
  }

  // 修改扫描WiFi方法以包含更多信息
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

        // 处理频率信息
        String? frequency = network.frequency?.toString();

        // 确定WiFi标准和频段
        String? band;
        String? standard;
        String? channel;

        if (frequency != null) {
          double freq = double.tryParse(frequency) ?? 0;

          // 确定频段
          if (freq > 5900) {
            band = '6G';
            standard = 'WiFi 6';
          } else if (freq > 5000) {
            band = '5G';
            standard = 'WiFi 5';
          } else if (freq > 2400) {
            band = '2.4G';
            standard = 'WiFi 4';
          }

          // 计算信道
          if (freq >= 2412 && freq <= 2484) {
            if (freq == 2484) {
              channel = '14';
            } else {
              channel = ((freq - 2412) / 5 + 1).round().toString();
            }
          } else if (freq >= 5170 && freq <= 5825) {
            channel = ((freq - 5170) / 5 + 34).round().toString();
          }
        }

        // 创建WiFi网络对象
        WiFiNetwork wifiNetwork = WiFiNetwork(
          name: network.ssid ?? "未知网络",
          encryption: encryption,
          signal: signalStrength,
          isSelected: _wifiList.isEmpty
              ? true
              : (network.ssid ?? "") == _crackingStatus.wifiName,
          bssid: network.bssid,
          frequency: frequency,
          channel: channel,
          standard: standard,
          band: band,
        );

        scannedNetworks.add(wifiNetwork);
      }

      // 更新状态
      setState(() {
        if (scannedNetworks.isNotEmpty) {
          // 按信号强度排序（从强到弱）
          scannedNetworks.sort((a, b) => b.signal.compareTo(a.signal));
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

            _hasSelectedWifi = true;
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

  // 显示WiFi密码输入对话框
  void _showPasswordDialog(WiFiNetwork network) {
    if (network.encryption == "Open") {
      // 如果是开放网络，直接尝试连接
      _connectToWiFi(network, "");
      return;
    }

    // 如果需要密码，显示输入对话框
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("连接到 ${network.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("请输入WiFi密码", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: '输入密码',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToWiFi(network, passwordController.text);
            },
            child: const Text("连接"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 连接到WiFi
  Future<void> _connectToWiFi(WiFiNetwork network, String password) async {
    ToastUtil.show(context, "正在连接到 ${network.name}...");

    try {
      bool success = await WiFiUtil.connectToWiFi(network.name, password);

      if (success) {
        ToastUtil.show(context, "成功连接到 ${network.name}", ToastType.success);

        // 更新网络状态
        setState(() {
          for (var wifi in _wifiList) {
            wifi.isConnected = (wifi.name == network.name);
            if (wifi.name == network.name) {
              wifi.password = password;
            }
          }
        });
      } else {
        ToastUtil.show(context, "连接失败，请检查密码", ToastType.error);
      }
    } catch (e) {
      ToastUtil.show(context, "连接WiFi时出错: $e", ToastType.error);
    }
  }

  // 当破解成功时保存结果
  void _saveWiFiCrackResult(WiFiNetwork network, String password) async {
    try {
      // 创建破解结果对象
      final crackResult = WiFiCrackResult(
        ssid: network.name,
        device: "Android设备", // 这里可以替换为实际设备信息
        bssid: network.bssid,
        channel: network.channel,
        ap: "", // 目前没有AP信息
        encryptionType: network.encryption,
        password: password,
        crackTime: DateTime.now(),
        band: network.band,
        standard: network.standard,
      );

      // 保存结果
      final saved = await WiFiUtil.saveWiFiCrackResult(crackResult);

      if (saved) {
        print('成功保存WiFi破解结果');
      } else {
        print('保存WiFi破解结果失败');
      }
    } catch (e) {
      print('保存WiFi破解结果时出错: $e');
    }
  }

  void _toggleCracking() {
    if (!_hasSelectedWifi) {
      ToastUtil.show(context, "请先选择一个WiFi网络", ToastType.warning);
      return;
    }

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
          ToastUtil.show(context, "WiFi密码破解成功：123456", ToastType.success);

          // 找到选中的WiFi网络
          final selectedWiFi = _wifiList.firstWhere((wifi) => wifi.isSelected,
              orElse: () => _wifiList.first);

          // 保存破解结果
          _saveWiFiCrackResult(selectedWiFi, "123456");
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

      // 清除破解状态但保留字典设置
      _crackingStatus = CrackingStatus(
        wifiName: network.name,
        dictionaryName: _crackingStatus.dictionaryName,
        dictionarySize: _crackingStatus.dictionarySize,
        estimatedTime: "未开始",
        currentProgress: "未开始",
        progressPercent: 0.0,
      );

      _hasSelectedWifi = true; // 设置为已选中WiFi
    });
    ToastUtil.show(context, "已选择WiFi: ${network.name}");
  }

  // 开始破解WiFi
  void _startCrackWifi(WiFiNetwork network) {
    if (_isLocked && network.name != _crackingStatus.wifiName) {
      ToastUtil.show(context, "当前WiFi已锁定，请先解锁", ToastType.warning);
      return;
    }

    // 先选中该WiFi
    setState(() {
      for (var wifi in _wifiList) {
        wifi.isSelected = wifi.name == network.name;
      }

      // 更新破解状态
      _crackingStatus = CrackingStatus(
        wifiName: network.name,
        dictionaryName: _crackingStatus.dictionaryName,
        dictionarySize: _crackingStatus.dictionarySize,
        estimatedTime: "计算中...",
        currentProgress: "准备中...",
        progressPercent: 0.0,
      );

      _hasSelectedWifi = true; // 设置为已选中WiFi

      // 自动开始破解
      _isCracking = true;
    });

    ToastUtil.show(context, "开始破解WiFi: ${network.name}");
    _startCrackingSimulation();
  }

  // 修改选择字典的方法，弹出底部抽屉
  void _navigateToDictionary() {
    _showDictionariesBottomSheet();
  }

  // 显示字典选择底部抽屉
  void _showDictionariesBottomSheet() async {
    try {
      final dictionaries = await FileUtil.getDictionaryFiles();

      if (dictionaries.isEmpty) {
        ToastUtil.show(context, "未找到字典文件", ToastType.warning);
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.book, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '选择字典',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dictionaries.length,
                    itemBuilder: (context, index) {
                      final dict = dictionaries[index];
                      final isSelected =
                          dict['name'] == _crackingStatus.dictionaryName;

                      return ListTile(
                        leading: Icon(
                          AppIcons.description,
                          color:
                              isSelected ? AppColors.primary : AppColors.gray,
                        ),
                        title: Text(dict['name']),
                        subtitle: Row(
                          children: [
                            Text(dict['size']),
                            const SizedBox(width: 8),
                            Text('${dict['entries']}条'),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _crackingStatus = CrackingStatus(
                              wifiName: _crackingStatus.wifiName,
                              dictionaryName: dict['name'],
                              dictionarySize: dict['size'],
                              estimatedTime: _crackingStatus.estimatedTime,
                              currentProgress: _crackingStatus.currentProgress,
                              progressPercent: _crackingStatus.progressPercent,
                            );
                          });
                          Navigator.pop(context);
                          ToastUtil.show(context, "已选择字典: ${dict['name']}",
                              ToastType.success);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('加载字典文件失败: $e');
      ToastUtil.show(context, "加载字典文件失败", ToastType.error);
    }
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
            const Text('WiFi Cracker', style: TextStyle(color: Colors.white)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 226, 226, 226)),
                      ),
                    )
                  : Icon(AppIcons.search, color: Colors.white),
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
                  onPressed: _hasSelectedWifi ? _toggleLock : null,
                  icon: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: _isLocked
                        ? AppColors.wpa2
                        : (_hasSelectedWifi
                            ? AppColors.gray
                            : Colors.grey.withOpacity(0.3)),
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
                              TextSpan(
                                text: _hasSelectedWifi
                                    ? _crackingStatus.wifiName
                                    : "未选择WiFi设备",
                                style: _hasSelectedWifi
                                    ? null
                                    : TextStyle(color: AppColors.gray),
                              ),
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
                        TextSpan(
                          text: _hasSelectedWifi
                              ? _crackingStatus.estimatedTime
                              : "未选择WiFi设备",
                          style: _hasSelectedWifi
                              ? null
                              : TextStyle(color: AppColors.gray),
                        ),
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
                        TextSpan(
                          text: _hasSelectedWifi
                              ? _crackingStatus.currentProgress
                              : "未选择WiFi设备",
                          style: _hasSelectedWifi
                              ? null
                              : TextStyle(color: AppColors.gray),
                        ),
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
                          onPressed: _hasSelectedWifi ? _toggleCracking : null,
                          icon: Icon(
                              _isCracking ? AppIcons.pause : AppIcons.play),
                          label: Text(_isCracking ? '暂停' : '开始'),
                          style: _hasSelectedWifi
                              ? AppStyles.successButtonStyle
                              : ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                ),
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
    // 构建WiFi信息标签
    List<Widget> infoTags = [];

    // 加密类型标签
    infoTags.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _getEncryptionColor(wifi.encryption).withOpacity(0.1),
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
    );

    // 如果有频段信息，添加频段标签
    if (wifi.band != null) {
      infoTags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            wifi.band!,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // 如果有WiFi标准信息，添加标准标签
    if (wifi.standard != null) {
      infoTags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            wifi.standard!,
            style: const TextStyle(
              color: Colors.purple,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // 如果有信道信息，添加信道标签
    if (wifi.channel != null) {
      infoTags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "CH${wifi.channel}",
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // 如果已连接，添加已连接标签
    if (wifi.isConnected) {
      infoTags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "已连接",
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        if (wifi.bssid != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              wifi.bssid!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppIcons.signal,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text('${wifi.signal}%'),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // 添加破解按钮
                      ElevatedButton.icon(
                        onPressed: () => _startCrackWifi(wifi),
                        icon: Icon(AppIcons.key, size: 16),
                        label: const Text('破解'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(20, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: infoTags,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPasswordDialog(wifi),
                    icon: Icon(
                      Icons.wifi_password,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    label: const Text('连接'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(20, 32),
                    ),
                  ),
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
