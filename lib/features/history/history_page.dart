import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/wifi_model.dart';
import '../../utils/toast_util.dart';
import '../../utils/history_util.dart';
import '../../resources/app_colors.dart';
import '../../resources/app_styles.dart';
import '../../resources/app_icons.dart';
import '../../resources/app_images.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _query = '';
  List<WiFiCrackResult> _historyItems = [];
  bool _isLoading = true;
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final history = await HistoryUtil.getHistory();
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    } catch (e) {
      print('加载历史记录失败: $e');
      setState(() {
        _isLoading = false;
      });
      ToastUtil.show(context, "加载历史记录失败", ToastType.error);
    }
  }

  List<WiFiCrackResult> get _filteredHistory {
    if (_query.isEmpty) {
      return _historyItems;
    }
    return _historyItems.where((item) {
      return item.ssid.toLowerCase().contains(_query.toLowerCase()) ||
          item.password.toLowerCase().contains(_query.toLowerCase()) ||
          (item.bssid?.toLowerCase().contains(_query.toLowerCase()) ?? false);
    }).toList();
  }

  Future<void> _deleteHistory(int index) async {
    try {
      final success = await HistoryUtil.deleteHistoryItem(index);
      if (success) {
        setState(() {
          _historyItems.removeAt(index);
        });
        ToastUtil.show(context, "已删除历史记录", ToastType.success);
      } else {
        ToastUtil.show(context, "删除历史记录失败", ToastType.error);
      }
    } catch (e) {
      print('删除历史记录失败: $e');
      ToastUtil.show(context, "删除历史记录失败", ToastType.error);
    }
  }

  Future<void> _copyPassword(WiFiCrackResult history) async {
    try {
      await Clipboard.setData(ClipboardData(text: history.password));
      ToastUtil.show(context, "已复制密码: ${history.password}", ToastType.success);
    } catch (e) {
      print('复制密码失败: $e');
      ToastUtil.show(context, "复制密码失败", ToastType.error);
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedIndices.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除选中的 ${_selectedIndices.length} 条历史记录吗？此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await HistoryUtil.deleteHistoryItems(
                    _selectedIndices.toList());
                if (success) {
                  setState(() {
                    _selectedIndices.clear();
                    _loadHistory();
                  });
                  ToastUtil.show(context, "已删除选中的历史记录", ToastType.success);
                } else {
                  ToastUtil.show(context, "删除历史记录失败", ToastType.error);
                }
              } catch (e) {
                print('批量删除历史记录失败: $e');
                ToastUtil.show(context, "删除历史记录失败", ToastType.error);
              }
            },
            child: const Text("确认删除"),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除所有历史记录吗？此操作无法撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await HistoryUtil.clearHistory();
                if (success) {
                  setState(() {
                    _historyItems.clear();
                    _selectedIndices.clear();
                  });
                  ToastUtil.show(context, "已清空所有历史记录", ToastType.success);
                } else {
                  ToastUtil.show(context, "清空历史记录失败", ToastType.error);
                }
              } catch (e) {
                print('清空历史记录失败: $e');
                ToastUtil.show(context, "清空历史记录失败", ToastType.error);
              }
            },
            child: const Text("确认删除"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('破解历史', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: Icon(AppIcons.deleteSweep, color: Colors.white),
              onPressed: _clearAllHistory,
              tooltip: '清空历史记录',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selectedIndices.isNotEmpty) _buildSelectionBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        decoration: InputDecoration(
          hintText: '搜索历史记录...',
          prefixIcon: Icon(AppIcons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.withValues(
            red: Colors.grey.r.toDouble(),
            green: Colors.grey.g.toDouble(),
            blue: Colors.grey.b.toDouble(),
            alpha: 0.1,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primary.withValues(
            red: Theme.of(context).colorScheme.primary.r.toDouble(),
            green: Theme.of(context).colorScheme.primary.g.toDouble(),
            blue: Theme.of(context).colorScheme.primary.b.toDouble(),
            alpha: 0.1,
          ),
      child: Row(
        children: [
          Text(
            '已选择 ${_selectedIndices.length} 项',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _deleteSelectedItems,
            icon: Icon(AppIcons.delete, color: Colors.red),
            label: const Text('删除选中', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppImages.emptyHistory,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无破解历史',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '成功破解的WiFi将会显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final history = _filteredHistory[index];
        return _buildHistoryItem(history, index);
      },
    );
  }

  Widget _buildHistoryItem(WiFiCrackResult history, int index) {
    final isSelected = _selectedIndices.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.itemBorderRadius,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withValues(
                  red: Colors.grey.r.toDouble(),
                  green: Colors.grey.g.toDouble(),
                  blue: Colors.grey.b.toDouble(),
                  alpha: 0.1,
                ),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onLongPress: () {
          setState(() {
            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
        onTap: _selectedIndices.isNotEmpty
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedIndices.remove(index);
                  } else {
                    _selectedIndices.add(index);
                  }
                });
              }
            : null,
        borderRadius: AppStyles.itemBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                            red: Theme.of(context)
                                .colorScheme
                                .primary
                                .r
                                .toDouble(),
                            green: Theme.of(context)
                                .colorScheme
                                .primary
                                .g
                                .toDouble(),
                            blue: Theme.of(context)
                                .colorScheme
                                .primary
                                .b
                                .toDouble(),
                            alpha: 0.1,
                          ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AppIcons.wifiLock,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.ssid,
                          style: AppStyles.title,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '密码: ${history.password}',
                          style: TextStyle(
                            color: AppColors.gray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (history.bssid != null)
                    _buildInfoChip(
                      icon: AppIcons.router,
                      label: history.bssid!,
                    ),
                  if (history.channel != null)
                    _buildInfoChip(
                      icon: AppIcons.signal,
                      label: 'CH${history.channel}',
                    ),
                  _buildInfoChip(
                    icon: null,
                    label: history.encryptionType,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(
                              red: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .r
                                  .toDouble(),
                              green: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .g
                                  .toDouble(),
                              blue: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .b
                                  .toDouble(),
                              alpha: 0.1,
                            ),
                    textColor: Theme.of(context).colorScheme.primary,
                  ),
                  _buildInfoChip(
                    icon: AppIcons.history,
                    label: _formatDate(history.crackTime),
                  ),
                  const Spacer(),
                  if (!_selectedIndices.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            AppIcons.copy,
                            size: 20,
                            color: AppColors.gray,
                          ),
                          onPressed: () => _copyPassword(history),
                          tooltip: '复制密码',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            AppIcons.delete,
                            size: 20,
                            color: AppColors.gray,
                          ),
                          onPressed: () => _deleteHistory(index),
                          tooltip: '删除记录',
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    IconData? icon,
    required String label,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Colors.grey.withValues(
              red: Colors.grey.r.toDouble(),
              green: Colors.grey.g.toDouble(),
              blue: Colors.grey.b.toDouble(),
              alpha: 0.1,
            ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: textColor ?? AppColors.gray,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}
