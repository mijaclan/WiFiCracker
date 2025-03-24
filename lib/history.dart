import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/wifi_model.dart';
import 'utils/toast_util.dart';
import 'resources/app_colors.dart';
import 'resources/app_styles.dart';
import 'resources/app_icons.dart';
import 'resources/app_images.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _query = '';

  final List<WiFiHistory> _historyItems = [
    WiFiHistory(
      ssid: "HomeWiFi",
      password: "password123",
      date: DateTime.now().subtract(const Duration(days: 1)),
      encryption: "WPA2",
      signalStrength: 85,
    ),
    WiFiHistory(
      ssid: "CoffeeShop",
      password: "coffee2022",
      date: DateTime.now().subtract(const Duration(days: 3)),
      encryption: "WPA",
      signalStrength: 72,
    ),
    WiFiHistory(
      ssid: "AirportFree",
      password: "airport123",
      date: DateTime.now().subtract(const Duration(days: 5)),
      encryption: "WEP",
      signalStrength: 65,
    ),
    WiFiHistory(
      ssid: "HotelWiFi",
      password: "hotel2023",
      date: DateTime.now().subtract(const Duration(days: 7)),
      encryption: "WPA2",
      signalStrength: 78,
    ),
  ];

  List<WiFiHistory> get _filteredHistory {
    if (_query.isEmpty) {
      return _historyItems;
    }
    return _historyItems
        .where((item) => item.ssid.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _deleteHistory(WiFiHistory history) {
    setState(() {
      _historyItems.removeWhere((item) => item.ssid == history.ssid);
    });
    ToastUtil.show(context, "已删除 ${history.ssid} 的历史记录");
  }

  void _copyPassword(WiFiHistory history) {
    ToastUtil.show(context, "已复制密码: ${history.password}", ToastType.success);
  }

  void _deleteAllHistory() {
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _historyItems.clear();
              });
              ToastUtil.show(context, "已清空所有历史记录");
            },
            child: const Text("确认删除"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month}/${date.day}";
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
              onPressed: _deleteAllHistory,
              tooltip: '清空历史记录',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredHistory.isEmpty
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
          fillColor: Colors.grey.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
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
        return _buildHistoryItem(history);
      },
    );
  }

  Widget _buildHistoryItem(WiFiHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.itemBorderRadius,
      ),
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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                _buildInfoChip(
                  icon: AppIcons.signal,
                  label: '${history.signalStrength}%',
                ),
                _buildInfoChip(
                  icon: null,
                  label: history.encryption,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  textColor: Theme.of(context).colorScheme.primary,
                ),
                _buildInfoChip(
                  icon: AppIcons.history,
                  label: _formatDate(history.date),
                ),
                const Spacer(),
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
                      onPressed: () => _deleteHistory(history),
                      tooltip: '删除记录',
                    ),
                  ],
                ),
              ],
            ),
          ],
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
        color: backgroundColor ?? Colors.grey.withOpacity(0.1),
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
