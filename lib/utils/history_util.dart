import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/wifi_model.dart';

class HistoryUtil {
  static const String _historyFileName = 'crackerHistory.json';

  // 初始化历史记录文件
  static Future<void> initHistoryFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      if (!await file.exists()) {
        // 如果文件不存在，创建一个空的JSON数组
        await file.writeAsString('[]');
        print('已创建历史记录文件: ${file.path}');
      }
    } catch (e) {
      print('初始化历史记录文件失败: $e');
    }
  }

  // 保存WiFi破解结果到历史记录
  static Future<bool> saveToHistory(WiFiCrackResult result) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      // 读取现有记录
      List<WiFiCrackResult> history = await getHistory();

      // 添加新记录
      history.add(result);

      // 将结果转换为JSON字符串
      final jsonList = history.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // 写入文件
      await file.writeAsString(jsonString);
      print('已保存到历史记录: ${file.path}');
      return true;
    } catch (e) {
      print('保存到历史记录失败: $e');
      return false;
    }
  }

  // 获取所有历史记录
  static Future<List<WiFiCrackResult>> getHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      if (!await file.exists()) {
        return [];
      }

      // 读取文件内容
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      // 解析结果
      return jsonList
          .map((json) => WiFiCrackResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('读取历史记录失败: $e');
      return [];
    }
  }

  // 删除单条历史记录
  static Future<bool> deleteHistoryItem(int index) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      // 读取现有记录
      List<WiFiCrackResult> history = await getHistory();

      // 删除指定索引的记录
      if (index >= 0 && index < history.length) {
        history.removeAt(index);

        // 将结果转换为JSON字符串
        final jsonList = history.map((r) => r.toJson()).toList();
        final jsonString = jsonEncode(jsonList);

        // 写入文件
        await file.writeAsString(jsonString);
        print('已删除历史记录项: $index');
        return true;
      }
      return false;
    } catch (e) {
      print('删除历史记录项失败: $e');
      return false;
    }
  }

  // 批量删除历史记录
  static Future<bool> deleteHistoryItems(List<int> indices) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      // 读取现有记录
      List<WiFiCrackResult> history = await getHistory();

      // 从大到小排序索引，以避免删除时影响其他索引
      indices.sort((a, b) => b.compareTo(a));

      // 删除指定索引的记录
      for (int index in indices) {
        if (index >= 0 && index < history.length) {
          history.removeAt(index);
        }
      }

      // 将结果转换为JSON字符串
      final jsonList = history.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // 写入文件
      await file.writeAsString(jsonString);
      print('已批量删除历史记录项: $indices');
      return true;
    } catch (e) {
      print('批量删除历史记录项失败: $e');
      return false;
    }
  }

  // 清空所有历史记录
  static Future<bool> clearHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_historyFileName');

      // 写入空数组
      await file.writeAsString('[]');
      print('已清空历史记录');
      return true;
    } catch (e) {
      print('清空历史记录失败: $e');
      return false;
    }
  }
} 