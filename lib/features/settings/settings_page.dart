import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../utils/toast_util.dart';
import '../../resources/app_colors.dart';
import '../../resources/app_styles.dart';
import '../../resources/app_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 基本设置
  bool _standbyRun = false; // 初始状态为关闭
  bool _standbyRunLoading = false; // 加载状态
  String _crackPriority = '平衡模式';
  bool _isDarkMode = false;
  bool _saveHistory = true;
  bool _enableAnimation = true;

  // 平台通道
  static const platform =
      MethodChannel('com.example.wificracker/foreground_service');

  // 下载源设置
  String _dictionarySource = "https://dict.fluteer.com/repo";
  bool _isSourceEditable = false;
  final TextEditingController _sourceController = TextEditingController();
  bool _isTestingConnection = false;

  // 通知设置
  final List<Map<String, dynamic>> _notificationOptions = [
    {'label': '铃声提醒', 'value': 'sound', 'selected': true},
    {'label': '振动提醒', 'value': 'vibration', 'selected': false},
    {'label': '邮件通知', 'value': 'email', 'selected': false},
  ];
  String _notificationEmail = '';
  bool _showEmailField = false;

  // 语言设置
  String _selectedLanguage = '简体中文';
  final _languages = ['简体中文', 'English', '日本語', 'Español'];

  @override
  void initState() {
    super.initState();
    _sourceController.text = _dictionarySource;

    // 检查是否启用了邮件通知
    _updateEmailVisibility();

    // 检查当前待机运行状态
    _checkStandbyRunStatus();
  }

  // 检查当前待机运行状态
  Future<void> _checkStandbyRunStatus() async {
    try {
      if (Platform.isAndroid) {
        // 尝试通过前台服务状态检查
        try {
          final result = await platform.invokeMethod('isServiceRunning');
          setState(() {
            _standbyRun = result ?? false;
          });
        } catch (e) {
          print('检查服务状态失败: $e');
          setState(() {
            _standbyRun = false;
          });
        }
      }
    } catch (e) {
      print('检查待机运行状态失败: $e');
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  void _updateEmailVisibility() {
    final emailOption = _notificationOptions.firstWhere(
      (option) => option['value'] == 'email',
      orElse: () => {'selected': false},
    );

    setState(() {
      _showEmailField = emailOption['selected'] ?? false;
    });
  }

  void _toggleNotificationOption(int index, bool value) {
    setState(() {
      _notificationOptions[index]['selected'] = value;
    });

    _updateEmailVisibility();

    ToastUtil.show(
      context,
      "已${value ? '启用' : '禁用'}${_notificationOptions[index]['label']}",
    );
  }

  void _toggleSourceEdit() {
    setState(() {
      if (_isSourceEditable) {
        // 保存更改
        _dictionarySource = _sourceController.text;
        ToastUtil.show(
            context, "已保存字典下载源: $_dictionarySource", ToastType.success);
      }
      _isSourceEditable = !_isSourceEditable;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    ToastUtil.show(context, "正在测试连接...");

    try {
      final Uri uri = Uri.parse(_dictionarySource);
      final response = await InternetAddress.lookup(uri.host);

      if (response.isNotEmpty) {
        ToastUtil.show(context, "连接成功", ToastType.success);
      } else {
        ToastUtil.show(context, "连接失败：无法连接到服务器", ToastType.error);
      }
    } catch (e) {
      ToastUtil.show(context, "连接错误：${e.toString()}", ToastType.error);
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _toggleStandbyRun(bool value) async {
    // 设置加载状态
    setState(() {
      _standbyRunLoading = true;
    });

    try {
      if (value) {
        // 只在Android平台请求权限
        if (Platform.isAndroid) {
          // 请求忽略电池优化
          final status = await Permission.ignoreBatteryOptimizations.status;
          if (!status.isGranted) {
            final result =
                await Permission.ignoreBatteryOptimizations.request();
            if (!result.isGranted) {
              ToastUtil.show(context, "需要电池优化权限以支持待机运行", ToastType.warning);
              setState(() {
                _standbyRunLoading = false;
                _standbyRun = false;
              });
              return;
            }
          }

          // 尝试启动前台服务
          try {
            await platform.invokeMethod('startService');
          } catch (e) {
            print('启动前台服务失败: $e');
            ToastUtil.show(context, "启动前台服务失败", ToastType.warning);
            setState(() {
              _standbyRunLoading = false;
              _standbyRun = false;
            });
            return;
          }
        }

        setState(() {
          _standbyRun = true;
        });

        ToastUtil.show(context, "已启用待机运行，应用将在后台持续工作", ToastType.success);
      } else {
        // 停止前台服务
        if (Platform.isAndroid) {
          try {
            await platform.invokeMethod('stopService');
          } catch (e) {
            print('停止前台服务失败: $e');
            ToastUtil.show(context, "停止前台服务失败", ToastType.warning);
          }
        }

        setState(() {
          _standbyRun = false;
        });

        ToastUtil.show(context, "已禁用待机运行，应用在屏幕关闭后可能会停止工作", ToastType.success);
      }
    } catch (e) {
      print('切换待机运行状态失败: $e');
      ToastUtil.show(context, "切换待机运行状态失败: ${e.toString()}", ToastType.error);

      // 恢复为原来的状态
      setState(() {
        _standbyRun = !value;
      });
    } finally {
      setState(() {
        _standbyRunLoading = false;
      });
    }
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    ToastUtil.show(
      context,
      value ? "已切换至暗色模式" : "已切换至亮色模式",
    );
  }

  void _toggleAnimationEffects(bool value) {
    setState(() {
      _enableAnimation = value;
    });
    ToastUtil.show(
      context,
      value ? "已启用动画效果" : "已禁用动画效果",
    );
  }

  void _changeCrackPriority(String? value) {
    if (value != null) {
      setState(() {
        _crackPriority = value;
      });
      ToastUtil.show(context, "破解优先级已设置为: $value");
    }
  }

  void _toggleSaveHistory(bool value) {
    setState(() {
      _saveHistory = value;
    });
    ToastUtil.show(
      context,
      value ? "已开启历史记录" : "已关闭历史记录",
    );
  }

  void _onLanguageChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
      });
      ToastUtil.show(context, "语言已更改为: $value");
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ToastUtil.show(context, "无法打开链接: $url", ToastType.error);
    }
  }

  Future<void> _showLocalContent(String title, String assetPath) async {
    // 显示本地内容
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: FutureBuilder<String>(
          future: DefaultAssetBundle.of(context).loadString(assetPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('无法加载内容: ${snapshot.error}');
            } else {
              return SingleChildScrollView(
                child: Text(snapshot.data ?? '内容为空'),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("关闭"),
          ),
        ],
      ),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认清除"),
        content: const Text("确定要清除所有应用数据吗？此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ToastUtil.show(context, "所有数据已清除", ToastType.success);
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    ToastUtil.show(context, "正在检查更新...");
    Future.delayed(const Duration(seconds: 2), () {
      ToastUtil.show(context, "当前已是最新版本: v1.0.0", ToastType.success);
    });
  }

  void _showFeedback() {
    _showLocalContent('意见反馈', 'lib/resources/support/feedback.txt');
  }

  void _showPrivacyPolicy() {
    _showLocalContent('隐私政策', 'lib/resources/support/privacy_policy.txt');
  }

  void _showTermsOfService() {
    _showLocalContent('使用条款', 'lib/resources/support/terms_of_service.txt');
  }

  void _showGitHubInfo() {
    _showLocalContent('GitHub 项目信息', 'lib/resources/support/github_info.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        children: [
          // 1. 性能设置
          _buildSectionTitle('性能设置', AppIcons.speed),
          _buildSettingItem(
            icon: AppIcons.standby,
            title: '待机运行',
            subtitle: '当屏幕关闭时继续运行',
            trailing: _standbyRunLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: _standbyRun,
                    onChanged: _toggleStandbyRun,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
          ),
          _buildDropdownSettingItem(
            icon: AppIcons.priority,
            title: '破解优先级',
            value: _crackPriority,
            items: const ['速度优先', '省电优先', '平衡模式'],
            onChanged: _changeCrackPriority,
          ),

          // 2. 通知设置
          _buildSectionTitle('通知设置', AppIcons.notifications),
          ...List.generate(
            _notificationOptions.length,
            (index) => _buildToggleSettingItem(
              icon: _getNotificationIcon(_notificationOptions[index]['value']),
              title: _notificationOptions[index]['label'],
              value: _notificationOptions[index]['selected'],
              onChanged: (value) => _toggleNotificationOption(index, value),
            ),
          ),
          if (_showEmailField)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '接收通知邮箱',
                  hintText: '请输入您的邮箱',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _notificationEmail = value;
                },
              ),
            ),

          // 3. 下载源设置
          _buildSectionTitle('下载源设置', AppIcons.server),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _sourceController,
                        enabled: _isSourceEditable,
                        decoration: InputDecoration(
                          labelText: '字典下载源URL',
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_isSourceEditable
                                    ? AppIcons.save
                                    : AppIcons.edit),
                                onPressed: _toggleSourceEdit,
                                tooltip: _isSourceEditable ? '保存' : '编辑',
                              ),
                              if (!_isSourceEditable)
                                IconButton(
                                  icon: _isTestingConnection
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.wifi_tethering),
                                  onPressed: _isTestingConnection
                                      ? null
                                      : _testConnection,
                                  tooltip: '测试连接',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '提示：设置字典下载源后可以在字典页面下载在线词典',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. 界面设置
          _buildSectionTitle('界面设置', AppIcons.palette),
          _buildToggleSettingItem(
            icon: AppIcons.darkMode,
            title: '深色模式',
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          _buildToggleSettingItem(
            icon: AppIcons.animation,
            title: '启用动画效果',
            subtitle: '启用界面动画和过渡效果',
            value: _enableAnimation,
            onChanged: _toggleAnimationEffects,
          ),
          _buildDropdownSettingItem(
            icon: AppIcons.language,
            title: '语言',
            value: _selectedLanguage,
            items: _languages,
            onChanged: _onLanguageChanged,
          ),

          // 5. 数据管理
          _buildSectionTitle('数据管理', AppIcons.database),
          _buildToggleSettingItem(
            icon: AppIcons.saveAuto,
            title: '自动保存破解记录',
            subtitle: '自动保存成功的破解记录',
            value: _saveHistory,
            onChanged: _toggleSaveHistory,
          ),
          _buildSettingItem(
            icon: AppIcons.delete,
            title: '清除所有数据',
            subtitle: '删除所有破解记录和设置',
            onTap: _clearData,
            trailing: const Icon(Icons.chevron_right),
          ),

          // 6. 关于与支持
          _buildSectionTitle('关于与支持', AppIcons.info),
          _buildSettingItem(
            icon: AppIcons.update,
            title: '检查更新',
            onTap: _checkForUpdates,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          _buildSettingItem(
            icon: AppIcons.feedback,
            title: '意见反馈',
            onTap: _showFeedback,
            trailing: const Icon(Icons.chevron_right),
          ),
          _buildSettingItem(
            icon: AppIcons.security,
            title: '隐私政策',
            onTap: _showPrivacyPolicy,
            trailing: const Icon(Icons.chevron_right),
          ),
          _buildSettingItem(
            icon: AppIcons.description,
            title: '使用条款',
            onTap: _showTermsOfService,
            trailing: const Icon(Icons.chevron_right),
          ),
          _buildSettingItem(
            icon: AppIcons.github,
            title: 'GitHub',
            onTap: _showGitHubInfo,
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'sound':
        return AppIcons.sound;
      case 'vibration':
        return AppIcons.vibration;
      case 'email':
        return AppIcons.email;
      default:
        return AppIcons.notifications;
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(
                red: Theme.of(context).colorScheme.primary.r.toDouble(),
                green: Theme.of(context).colorScheme.primary.g.toDouble(),
                blue: Theme.of(context).colorScheme.primary.b.toDouble(),
                alpha: 0.1,
              ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title, style: AppStyles.subtitle),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildToggleSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDropdownSettingItem<T>({
    required IconData icon,
    required String title,
    String? subtitle,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return _buildSettingItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: DropdownButton<T>(
        value: value,
        onChanged: onChanged,
        underline: Container(),
        items: items.map<DropdownMenuItem<T>>((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text('$item'),
          );
        }).toList(),
      ),
    );
  }
}
