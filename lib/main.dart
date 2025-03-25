import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'home.dart';
import 'dictionary.dart';
import 'history.dart';
import 'settings.dart';
import 'resources/app_colors.dart';
import 'utils/file_util.dart';
import 'package:permission_handler/permission_handler.dart';

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

        return MainScreen(key: mainScreenKey);
      }),
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

  final List<Widget> _screens = [
    const HomePage(),
    const DictionaryPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  // 提供一个公共方法来设置当前索引
  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
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
