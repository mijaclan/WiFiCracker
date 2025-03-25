import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'models/wifi_model.dart';
import 'utils/toast_util.dart';
import 'utils/file_util.dart';
import 'resources/app_colors.dart';
import 'resources/app_styles.dart';
import 'resources/app_icons.dart';
import 'resources/app_images.dart';
import 'package:file_picker/file_picker.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  String _dictionarySource = "https://dict.fluteer.com/repo";
  late Future<String> _dictionaryPathFuture;
  bool _isConnecting = false;
  bool _isConnectionValid = false;
  bool _isLoading = false;
  List<Dictionary> _localDictionaries = [];
  bool _isLoadingLocalDictionaries = false;

  // 添加刷新冷却时间控制
  DateTime _lastLocalRefreshTime =
      DateTime.now().subtract(const Duration(minutes: 1));
  DateTime _lastRemoteRefreshTime =
      DateTime.now().subtract(const Duration(minutes: 1));
  static const Duration _refreshCooldown = Duration(seconds: 10); // 冷却时间为10秒

  // 模拟远程字典列表
  final List<Dictionary> _remoteDictionaries = [
    Dictionary(
      name: "rockyou.txt",
      size: "133MB",
      entries: "14,341,564",
    ),
    Dictionary(
      name: "wifi_common.txt",
      size: "8.6MB",
      entries: "50,000",
    ),
    Dictionary(
      name: "default_router_passwords.txt",
      size: "2.1MB",
      entries: "5,000",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dictionaryPathFuture = FileUtil.getDictionaryPath();
    _loadLocalDictionaries();
  }

  // 加载本地字典列表
  Future<void> _loadLocalDictionaries() async {
    // 检查是否在冷却时间内
    final now = DateTime.now();
    if (now.difference(_lastLocalRefreshTime) < _refreshCooldown) {
      ToastUtil.show(context, "请稍后再刷新", ToastType.warning);
      return;
    }

    // 更新刷新时间
    _lastLocalRefreshTime = now;

    setState(() {
      _isLoadingLocalDictionaries = true;
    });

    try {
      final dictionaries = await FileUtil.getDictionaryFiles();

      setState(() {
        _localDictionaries = dictionaries
            .map((dict) => Dictionary(
                  name: dict['name'],
                  size: dict['size'],
                  entries: dict['entries'],
                ))
            .toList();
        _isLoadingLocalDictionaries = false;
      });
    } catch (e) {
      print('加载本地字典失败: $e');
      setState(() {
        _localDictionaries = [];
        _isLoadingLocalDictionaries = false;
      });
    }
  }

  void _selectDictionary(Dictionary dictionary) {
    setState(() {
      for (var dict in _localDictionaries) {
        dict.selected = dict.name == dictionary.name;
      }
    });
    ToastUtil.show(context, "已选择字典: ${dictionary.name}");
  }

  void _deleteDictionary(Dictionary dictionary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除字典 ${dictionary.name} 吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dictionaryPath = await FileUtil.getDictionaryPath();
                final file = File('$dictionaryPath/${dictionary.name}');
                if (await file.exists()) {
                  await file.delete();
                  await _loadLocalDictionaries(); // 重新加载列表
                  ToastUtil.show(context, "已删除字典: ${dictionary.name}");
                }
              } catch (e) {
                print('删除字典文件失败: $e');
                ToastUtil.show(context, "删除字典失败", ToastType.error);
              }
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  void _downloadDictionary(Dictionary dictionary) {
    ToastUtil.show(context, "正在下载字典: ${dictionary.name}");
    // 模拟下载过程
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        // 检查是否已存在
        bool exists =
            _localDictionaries.any((dict) => dict.name == dictionary.name);
        if (!exists) {
          _localDictionaries.add(dictionary);
        }
      });
      ToastUtil.show(context, "字典下载完成: ${dictionary.name}", ToastType.success);
    });
  }

  void _verifyConnection() {
    setState(() {
      _isConnecting = true;
    });

    // 模拟网络验证
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isConnecting = false;
        _isConnectionValid = true;
      });
      ToastUtil.show(context, "下载源连接验证成功", ToastType.success);
    });
  }

  void _saveDictionarySource() {
    ToastUtil.show(context, "已保存字典下载源: $_dictionarySource");
  }

  // 编辑字典路径
  Future<void> _editDictionaryPath() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await FileUtil.updateDictionaryPath(result);
        setState(() {
          _dictionaryPathFuture = FileUtil.getDictionaryPath();
        });
        await _loadLocalDictionaries(); // 重新加载字典列表
        ToastUtil.show(context, "字典路径已更新，文件已移动到新位置", ToastType.success);
      }
    } catch (e) {
      print('更改字典路径失败: $e');
      ToastUtil.show(context, "更改字典路径失败: ${e.toString()}", ToastType.error);
    }
  }

  void _refreshRemoteDictionaries() {
    // 检查是否在冷却时间内
    final now = DateTime.now();
    if (now.difference(_lastRemoteRefreshTime) < _refreshCooldown) {
      ToastUtil.show(context, "请稍后再刷新", ToastType.warning);
      return;
    }

    // 更新刷新时间
    _lastRemoteRefreshTime = now;

    setState(() {
      _isLoading = true;
    });

    // 模拟网络请求
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ToastUtil.show(context, "远程字典列表已刷新");
    });
  }

  void _useDictionary(Dictionary dictionary) {
    // 检查是否有选中的WiFi
    bool hasSelectedWifi = true; // 实际应用中应该检查主页的WiFi选择状态

    if (hasSelectedWifi) {
      // 使用该字典开始跑包，不改变WiFi锁定状态
      ToastUtil.show(
          context, "开始使用字典: ${dictionary.name} 进行破解", ToastType.success);

      // 这里实际上应该调用主页的方法来启动破解过程
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context); // 返回主页
      });
    } else {
      ToastUtil.show(context, "请先在主页选择WiFi网络", ToastType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字典管理', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDictionarySourceCard(),
            const SizedBox(height: 16),
            _buildDictionaryPathCard(),
            const SizedBox(height: 16),
            _buildRemoteDictionariesCard(),
            const SizedBox(height: 16),
            _buildLocalDictionariesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDictionarySourceCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.server, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '字典下载源',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _dictionarySource),
              onChanged: (value) {
                _dictionarySource = value;
              },
              decoration: InputDecoration(
                hintText: '输入下载源URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _verifyConnection,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isConnectionValid
                          ? AppIcons.checkCircle
                          : AppIcons.check),
                  label: Text(_isConnecting ? '验证中...' : '验证连接'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveDictionarySource,
                  icon: Icon(AppIcons.save),
                  label: const Text('保存设置'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDictionaryPathCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.folder, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '字典路径',
                  style: AppStyles.cardTitle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _dictionaryPathFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(
                    '获取路径失败: ${snapshot.error}',
                    style: TextStyle(color: AppColors.error),
                  );
                }

                final path = snapshot.data ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path,
                      style: AppStyles.cardSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _editDictionaryPath,
                          icon: Icon(AppIcons.folderOpen,
                              color: AppColors.primary),
                          label: Text(
                            '更改路径',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteDictionariesCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppStyles.cardBorderRadius.topLeft.x),
                topRight:
                    Radius.circular(AppStyles.cardBorderRadius.topRight.x),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.cloudDownload, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '远程字典',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshRemoteDictionaries,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(AppIcons.refresh),
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          if (_isConnectionValid && _remoteDictionaries.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _remoteDictionaries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final dictionary = _remoteDictionaries[index];
                return _buildRemoteDictionaryItem(dictionary);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppImages.emptyDictionary,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isConnectionValid ? '无可用的远程字典' : '未连接到下载源',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteDictionaryItem(Dictionary dictionary) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        dictionary.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(AppIcons.database, size: 14, color: AppColors.gray),
          const SizedBox(width: 4),
          Text(dictionary.size),
          const SizedBox(width: 8),
          Icon(AppIcons.list, size: 14, color: AppColors.gray),
          const SizedBox(width: 4),
          Text('${dictionary.entries}条'),
        ],
      ),
      trailing: IconButton(
        icon: Icon(AppIcons.download,
            color: Theme.of(context).colorScheme.secondary),
        onPressed: () => _downloadDictionary(dictionary),
        tooltip: '下载',
      ),
    );
  }

  Widget _buildLocalDictionariesCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.cardBorderRadius,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppStyles.cardBorderRadius.topLeft.x),
                topRight:
                    Radius.circular(AppStyles.cardBorderRadius.topRight.x),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.storage, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      '本地字典',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isLoadingLocalDictionaries
                      ? null
                      : _loadLocalDictionaries,
                  icon: _isLoadingLocalDictionaries
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(AppIcons.refresh),
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          if (_isLoadingLocalDictionaries)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_localDictionaries.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localDictionaries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final dictionary = _localDictionaries[index];
                return _buildLocalDictionaryItem(dictionary);
              },
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppImages.emptyDictionary,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '本地字典为空',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalDictionaryItem(Dictionary dictionary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              AppIcons.description,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dictionary.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(AppIcons.database, size: 14, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Text(dictionary.size,
                        style: TextStyle(color: AppColors.gray, fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(AppIcons.list, size: 14, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Text('${dictionary.entries}条',
                        style: TextStyle(color: AppColors.gray, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(AppIcons.play, color: AppColors.success),
                onPressed: () => _useDictionary(dictionary),
                tooltip: '使用',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(AppIcons.delete, color: AppColors.error),
                onPressed: () => _deleteDictionary(dictionary),
                tooltip: '删除',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
