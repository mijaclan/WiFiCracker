import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wifi_model.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WiFiUtil {
  static const String _crackResultsKey = 'wifi_crack_results';
  static const String _resultsFileName = 'wifi_crack_results.json';

  // 连接到WiFi网络
  static Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      bool success = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
      );
      
      if (success) {
        print('成功连接到WiFi: $ssid');
      } else {
        print('连接WiFi失败: $ssid');
      }
      
      return success;
    } catch (e) {
      print('连接WiFi时出错: $e');
      return false;
    }
  }

  // 从WiFiNetwork获取WiFi标准
  static String? getWiFiStandard(WiFiNetwork network) {
    if (network.frequency == null) return null;
    
    try {
      double freq = double.parse(network.frequency!);
      
      // 根据频率来判断WiFi标准 (简化判断)
      if (freq > 5000) {
        return 'WiFi 5 (5GHz)';
      } else {
        return 'WiFi 4 (2.4GHz)';
      }
    } catch (e) {
      return null;
    }
  }

  // 从频率获取WiFi频段
  static String? getWiFiBand(WiFiNetwork network) {
    if (network.frequency == null) return null;
    
    try {
      double freq = double.parse(network.frequency!);
      
      if (freq > 5900) {
        return '6G';
      } else if (freq > 5000) {
        return '5G';
      } else if (freq > 2400) {
        return '2.4G';
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 从WiFi原生信息提取信道
  static String? getWiFiChannel(WiFiNetwork network) {
    if (network.frequency == null) return null;
    
    try {
      double freq = double.parse(network.frequency!);
      int channel;
      
      // 2.4GHz频段信道计算
      if (freq >= 2412 && freq <= 2484) {
        if (freq == 2484) {
          return '14';  // 特殊情况，日本使用的2.4GHz频段14信道
        }
        channel = ((freq - 2412) / 5 + 1).round();
        return channel.toString();
      }
      
      // 5GHz频段信道计算 (简化)
      if (freq >= 5170 && freq <= 5825) {
        channel = ((freq - 5170) / 5 + 34).round();
        return channel.toString();
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // 保存WiFi破解结果
  static Future<bool> saveWiFiCrackResult(WiFiCrackResult result) async {
    try {
      // 1. 先获取之前保存的所有结果
      List<WiFiCrackResult> results = await getWiFiCrackResults();
      
      // 2. 添加新结果
      results.add(result);
      
      // 3. 保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonList = results.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_crackResultsKey, jsonList);
      
      // 4. 同时保存到文件
      await _saveResultsToFile(results);
      
      return true;
    } catch (e) {
      print('保存WiFi破解结果失败: $e');
      return false;
    }
  }
  
  // 获取所有WiFi破解结果
  static Future<List<WiFiCrackResult>> getWiFiCrackResults() async {
    try {
      // 1. 先尝试从SharedPreferences获取
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_crackResultsKey) ?? [];
      
      if (jsonList.isEmpty) {
        // 2. 如果SharedPreferences为空，尝试从文件读取
        return await _loadResultsFromFile();
      }
      
      // 3. 解析结果
      return jsonList
          .map((jsonStr) => WiFiCrackResult.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('获取WiFi破解结果失败: $e');
      return [];
    }
  }
  
  // 将结果保存到文件
  static Future<void> _saveResultsToFile(List<WiFiCrackResult> results) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_resultsFileName');
      
      // 将结果转换为JSON字符串
      final jsonList = results.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // 写入文件
      await file.writeAsString(jsonString);
      print('WiFi破解结果已保存到文件: ${file.path}');
    } catch (e) {
      print('保存WiFi破解结果到文件失败: $e');
    }
  }
  
  // 从文件加载结果
  static Future<List<WiFiCrackResult>> _loadResultsFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_resultsFileName');
      
      if (!await file.exists()) {
        print('WiFi破解结果文件不存在');
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
      print('从文件加载WiFi破解结果失败: $e');
      return [];
    }
  }
} 