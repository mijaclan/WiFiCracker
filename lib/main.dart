import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'features/home/home__page.dart';
import 'features/dictionary/dictionary_page.dart';
import 'features/history/history_page.dart';
import 'features/settings/settings_page.dart';
import 'resources/app_colors.dart';
import 'resources/app_images.dart';
import 'utils/file_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 全局key，用于访问MainScreen的状态
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

// 全局方法，用于切换底部导航栏
void navigateToTab(int index) {
  mainScreenKey.currentState?.setCurrentIndex(index);
}

void main() async {
  // 确保Flutter引擎初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showInitError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const String _permissionCheckedKey = 'permission_checked';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 延迟初始化，确保UI先渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // 初始化应用，包括检查并复制字典文件
  Future<void> _initializeApp() async {
    try {
      print('应用启动：开始初始化...');

      // 复制字典文件到应用目录
      await FileUtil.copyDictionaryFiles();
      print('应用启动：初始化完成');

      // 如果之前显示了错误，现在关闭它
      if (_showInitError) {
        setState(() {
          _showInitError = false;
        });
      }

      // 延迟2秒后关闭启动画面
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('应用启动：初始化失败: $e');

      if (_retryCount < maxRetries) {
        _retryCount++;
        print('尝试重试初始化 (${_retryCount}/${maxRetries})');

        // 延迟1秒后重试
        Future.delayed(const Duration(seconds: 1), () {
          _initializeApp();
        });
      } else {
        // 已达到最大重试次数，显示错误
        setState(() {
          _showInitError = true;
          _errorMessage = '字典文件初始化失败，但应用仍将以有限功能运行。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluteer WiFi Cracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: Builder(builder: (context) {
        // 如果需要显示错误提示，在底部添加一个Snackbar
        if (_showInitError) {
          // 使用Future.delayed确保build完成后再显示Snackbar
          Future.delayed(Duration.zero, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }

        return _isLoading
            ? const SplashScreen()
            : MainScreen(key: mainScreenKey);
      }),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // 创建安全的内边距
    final padding = MediaQuery.of(context).padding;
    final safeHeight = height - padding.top - padding.bottom;

    // 考虑不同设备屏幕比例
    final aspectRatio = width / height;

    // 根据不同设备进行调整
    // iPhone比例通常是9:19.5
    // Android设备则更多样化
    double logoScale = 1.0;

    // 根据屏幕尺寸调整缩放比例
    if (width < 375) {
      // 较小的设备如iPhone SE
      logoScale = 0.85;
    } else if (width > 428) {
      // 大尺寸设备如iPhone 15 Pro Max
      logoScale = 1.15;
    }

    // 处理Android 6.0的兼容性问题
    Widget svgWidget;
    try {
      svgWidget = SvgPicture.asset(
        AppImages.wifiBackground,
        fit: BoxFit.cover,
        width: width,
        height: height,
      );
    } catch (e) {
      // 如果SVG渲染失败，使用简单的颜色背景代替
      print('SVG渲染失败，使用备用方案: $e');
      svgWidget = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4a90e2),
              Color(0xFF2980b9),
            ],
          ),
        ),
        child: Center(
          child: Transform.scale(
            scale: logoScale,
            child: SvgPicture.asset(
              AppImages.wifiLogo,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景
          svgWidget,

          // 中央logo - 如果背景SVG中没有logo，则可以在这里添加
          if (Platform.isAndroid && Platform.version.startsWith('6.'))
            Center(
              child: Transform.scale(
                scale: logoScale,
                child: SvgPicture.asset(
                  AppImages.wifiLogo,
                  width: 100,
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _permissionChecked = false;

  final List<Widget> _screens = [
    const HomePage(),
    const DictionaryPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // 提供一个公共方法来设置当前索引
  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 检查应用所需的权限
  Future<void> _checkPermissions() async {
    // 检查是否已经请求过权限
    final prefs = await SharedPreferences.getInstance();
    _permissionChecked =
        prefs.getBool(_MyAppState._permissionCheckedKey) ?? false;

    if (!_permissionChecked) {
      // 延迟一下显示权限对话框，确保界面已完全加载
      Future.delayed(const Duration(milliseconds: 500), () {
        _showPermissionDialog();
      });
    }
  }

  // 显示权限请求对话框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 用户必须点击按钮
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要权限'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('为了正常运行，WiFi Cracker需要以下权限：'),
                const SizedBox(height: 10),
                if (Platform.isAndroid) ...[
                  _buildPermissionItem('位置信息', '扫描WiFi网络列表需要位置权限'),
                  _buildPermissionItem('WiFi状态', '查看和更改WiFi连接状态'),
                  _buildPermissionItem('存储空间', '读取和保存字典文件')
                ] else if (Platform.isIOS) ...[
                  _buildPermissionItem('本地网络', '连接到WiFi网络'),
                  _buildPermissionItem('文档访问', '读取和保存字典文件')
                ],
                const SizedBox(height: 15),
                const Text('请点击"授权"按钮开始权限授予流程。',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('稍后再说'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('授权'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
            ),
          ],
        );
      },
    );
  }

  // 构建权限项UI
  Widget _buildPermissionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 请求所需权限
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android权限请求
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location, // 位置权限 - 用于WiFi扫描
        Permission.storage, // 存储权限 - 用于读写文件
      ].request();

      // 检查WiFi权限
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (allGranted) {
        // 所有权限都已授予，标记为已检查
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_MyAppState._permissionCheckedKey, true);
        setState(() {
          _permissionChecked = true;
        });
      } else {
        // 提示用户手动授予权限
        _showManualPermissionInstructionsDialog();
      }
    } else if (Platform.isIOS) {
      // iOS没有直接的权限API，标记为已检查
      // 大多数iOS权限会在使用相关功能时自动请求
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_MyAppState._permissionCheckedKey, true);
      setState(() {
        _permissionChecked = true;
      });
    }
  }

  // 显示手动授权指南
  void _showManualPermissionInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要手动授权'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('部分权限未能自动授予，请按照以下步骤手动授权：'),
                const SizedBox(height: 10),
                const Text('1. 打开设备设置'),
                const Text('2. 找到 WiFi Cracker 应用'),
                const Text('3. 点击"权限"'),
                const Text('4. 开启所有需要的权限'),
                const SizedBox(height: 10),
                const Text('没有这些权限，应用的部分功能可能无法正常工作。'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('稍后再说'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('去设置'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // 打开应用设置页面
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '字典',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
