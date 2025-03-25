import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtil {
  static const String _prefsKey = 'dictionary_files_copied';
  static const String _lastScanKey = 'last_dictionary_scan_time';
  static const String _folderName = 'LocalDictionaries';
  static const String _appFolderName = 'wificracker';
  static const String _dictionaryPathKey = 'dictionary_path';
  static const Duration _scanInterval = Duration(minutes: 5); // 扫描间隔时间

  // 获取应用的字典存储目录（不需要权限）
  static Future<Directory> get _appDir async {
    Directory directory;

    try {
      // 在所有平台上使用应用的文档目录（这不需要特殊权限）
      directory = await getApplicationDocumentsDirectory();
      print('使用应用文档目录: ${directory.path}');
    } catch (e) {
      print('获取应用文档目录失败: $e，使用临时目录');
      directory = await getTemporaryDirectory();
    }

    // 创建应用专用文件夹
    final appFolder =
        Directory('${directory.path}${Platform.pathSeparator}$_appFolderName');
    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
      print('创建应用专用文件夹: ${appFolder.path}');
    } else {
      print('使用现有应用专用文件夹: ${appFolder.path}');
    }

    return appFolder;
  }

  // 获取或设置字典路径
  static Future<String> getDictionaryPath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(_dictionaryPathKey);

    if (savedPath == null) {
      // 如果没有保存过路径，创建默认路径
      final appDir = await _appDir;
      savedPath = '${appDir.path}${Platform.pathSeparator}$_folderName';

      // 验证路径是否有效
      final pathDir = Directory(savedPath);
      if (!await pathDir.exists()) {
        try {
          await pathDir.create(recursive: true);
          print('创建默认字典目录: $savedPath');
        } catch (e) {
          print('创建默认字典目录失败: $e，尝试使用应用目录');
          // 如果创建失败，尝试使用应用内目录
          final appDocDir = await getApplicationDocumentsDirectory();
          savedPath = '${appDocDir.path}${Platform.pathSeparator}$_folderName';
          await Directory(savedPath).create(recursive: true);
        }
      }

      // 保存路径
      await prefs.setString(_dictionaryPathKey, savedPath);
      print('保存默认字典路径: $savedPath');
    } else {
      // 检查已保存的路径是否仍然有效
      final pathDir = Directory(savedPath);
      if (!await pathDir.exists()) {
        try {
          // 尝试创建目录
          await pathDir.create(recursive: true);
          print('重新创建已保存的字典目录: $savedPath');
        } catch (e) {
          print('无法使用已保存的字典路径: $e，重置为默认路径');
          // 如果失败，重置为默认路径
          final appDir = await _appDir;
          savedPath = '${appDir.path}${Platform.pathSeparator}$_folderName';
          await Directory(savedPath).create(recursive: true);
          await prefs.setString(_dictionaryPathKey, savedPath);
        }
      } else {
        print('使用已保存的字典路径: $savedPath');
      }
    }

    return savedPath;
  }

  // 更新字典路径并移动文件
  static Future<void> updateDictionaryPath(String newPath) async {
    try {
      final oldPath = await getDictionaryPath();
      final oldDir = Directory(oldPath);
      final newDir = Directory(newPath);

      // 如果新旧路径相同，无需处理
      if (oldPath == newPath) {
        print('路径未变更，无需移动文件');
        return;
      }

      print('开始移动字典文件: $oldPath -> $newPath');

      // 确保新目录存在
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
        print('创建新的字典目录: $newPath');
      }

      // 如果旧目录存在且不为空，移动文件
      if (await oldDir.exists() && await _isDirectoryNotEmpty(oldDir)) {
        final files = await oldDir.list().toList();
        int movedCount = 0;

        print('开始移动 ${files.length} 个文件...');

        for (var entity in files) {
          if (entity is File && entity.path.endsWith('.txt')) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final newFile = File('$newPath${Platform.pathSeparator}$fileName');

            try {
              // 如果新位置已存在同名文件，先删除
              if (await newFile.exists()) {
                await newFile.delete();
              }

              // 复制文件到新位置
              await entity.copy(newFile.path);
              // 删除旧文件
              await entity.delete();
              movedCount++;
              print('成功移动文件: $fileName');
            } catch (e) {
              print('移动文件失败: ${entity.path} -> ${newFile.path}: $e');
              continue;
            }
          }
        }

        print('完成移动 $movedCount 个文件');
      } else {
        print('旧目录不存在或为空，无需移动文件');
      }

      // 更新路径
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dictionaryPathKey, newPath);
      print('更新字典路径为: $newPath');

      // 更新扫描时间
      await _updateLastScanTime();
    } catch (e) {
      print('更新字典路径时出错: $e');
      rethrow;
    }
  }

  // 检查是否需要扫描
  static Future<bool> _shouldScan() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScanTime = prefs.getInt(_lastScanKey);

    if (lastScanTime == null) {
      print('首次扫描，没有上次扫描时间记录');
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastScan = now - lastScanTime;

    // 如果距离上次扫描超过间隔时间，需要重新扫描
    if (timeSinceLastScan > _scanInterval.inMilliseconds) {
      print('距离上次扫描超过${_scanInterval.inMinutes}分钟，需要重新扫描');
      return true;
    }

    // 检查文件是否发生变化
    final dictionaryPath = await getDictionaryPath();
    final targetDir = Directory(dictionaryPath);

    if (!await targetDir.exists()) {
      print('字典目录不存在，需要重新扫描');
      return true;
    }

    try {
      // 获取目录中所有文件
      final List<FileSystemEntity> files = await targetDir.list().toList();

      if (files.isEmpty) {
        print('字典目录为空，需要重新扫描');
        return true;
      }

      // 获取目录中所有文件的最后修改时间
      final latestModification = files.fold<DateTime>(
        DateTime.fromMillisecondsSinceEpoch(0),
        (latest, file) {
          try {
            final stat = file.statSync();
            return stat.modified.isAfter(latest) ? stat.modified : latest;
          } catch (e) {
            print('获取文件修改时间失败: $e');
            return latest;
          }
        },
      );

      // 如果最新修改时间晚于上次扫描时间，需要重新扫描
      final needScan = latestModification.millisecondsSinceEpoch > lastScanTime;
      if (needScan) {
        print('文件有修改，需要重新扫描');
      } else {
        print('文件无变化，不需要重新扫描');
      }
      return needScan;
    } catch (e) {
      print('检查文件修改时间失败: $e');
      return true; // 出错时，保险起见，进行扫描
    }
  }

  // 更新最后扫描时间
  static Future<void> _updateLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastScanKey, DateTime.now().millisecondsSinceEpoch);
  }

  // 检查字典文件是否已复制
  static Future<bool> _checkFilesCopied() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  // 标记文件已复制
  static Future<void> _markFilesCopied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  // 公共权限检查方法 - 应用启动时调用
  static Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // 获取多个权限，增加成功率
        print('检查Android存储权限...');

        // 检查旧版存储权限
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          print('已获得基本存储权限');
          return true;
        }

        // 检查外部存储权限
        final externalStorageStatus =
            await Permission.manageExternalStorage.status;
        if (externalStorageStatus.isGranted) {
          print('已获得管理外部存储权限');
          return true;
        }

        // 默认请求基本存储权限
        print('请求基本存储权限...');
        final storageResult = await Permission.storage.request();

        if (storageResult.isGranted) {
          print('存储权限已授予');
          return true;
        }

        // 如果基本权限失败，尝试请求管理外部存储权限
        if (storageResult.isDenied || storageResult.isPermanentlyDenied) {
          print('基本存储权限被拒绝，尝试请求管理外部存储权限');
          final externalResult =
              await Permission.manageExternalStorage.request();

          if (externalResult.isGranted) {
            print('管理外部存储权限已授予');
            return true;
          }

          if (externalResult.isPermanentlyDenied) {
            print('管理外部存储权限被永久拒绝，需要用户在设置中手动开启');
          } else {
            print('管理外部存储权限被拒绝: $externalResult');
          }
        }

        // 尝试所有权限都失败了
        return false;
      } else if (Platform.isIOS) {
        // iOS平台默认可以访问其自己的沙盒
        return true;
      }

      // 其他平台默认返回true
      return true;
    } catch (e) {
      print('检查权限失败: $e');
      return false; // 出错时，返回false以便应用选择安全的路径
    }
  }

  // 复制字典文件到应用目录
  static Future<void> copyDictionaryFiles() async {
    try {
      // 获取目标路径
      final dictionaryPath = await getDictionaryPath();
      final targetDir = Directory(dictionaryPath);

      print('字典目标路径: $dictionaryPath');

      // 确保目标文件夹存在
      if (!await targetDir.exists()) {
        try {
          await targetDir.create(recursive: true);
          print('创建字典目录: $dictionaryPath');
        } catch (e) {
          print('创建字典目录失败: $e');
          throw Exception('无法创建字典目录: $e');
        }
      }

      // 检查目录是否为空或文件是否已复制
      final isNotEmpty = await _isDirectoryNotEmpty(targetDir);
      final filesCopied = await _checkFilesCopied();

      if (isNotEmpty && filesCopied) {
        print('字典目录不为空且文件已复制标记已设置，无需复制文件');
        return;
      }

      // 复制文件
      print('准备复制文件到字典目录: $dictionaryPath');

      // 清除标记，以便重新复制
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);

      // 获取资源列表
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);

        // 过滤出字典文件
        final dictionaryFiles = manifestMap.keys.where((String key) =>
            key.startsWith('lib/resources/$_folderName/') &&
            key.endsWith('.txt'));

        if (dictionaryFiles.isEmpty) {
          print('未在资源中找到字典文件，请检查pubspec.yaml中的assets配置');
          print('检查以下配置是否存在:\n  assets:\n    - lib/resources/$_folderName/');
          throw Exception('未找到字典文件');
        }

        print('找到 ${dictionaryFiles.length} 个资源字典文件，准备复制...');
        int copiedCount = 0;
        List<String> failedFiles = [];

        for (String filePath in dictionaryFiles) {
          final fileName = filePath.split('/').last;
          final targetFile =
              File('${targetDir.path}${Platform.pathSeparator}$fileName');

          try {
            print('复制文件: $filePath -> ${targetFile.path}');

            // 加载资源文件
            final data = await rootBundle.load(filePath);

            // 写入目标文件
            await targetFile.writeAsBytes(data.buffer.asUint8List());

            // 验证文件是否成功写入
            if (await targetFile.exists()) {
              final fileSize = await targetFile.length();
              if (fileSize > 0) {
                print('成功复制文件: $fileName (${fileSize} bytes)');
                copiedCount++;
              } else {
                print('警告: 复制的文件大小为0: $fileName');
                failedFiles.add(fileName);
              }
            } else {
              print('警告: 文件复制后不存在: $fileName');
              failedFiles.add(fileName);
            }
          } catch (e) {
            print('复制文件失败: $filePath -> ${targetFile.path}: $e');
            failedFiles.add(fileName);
          }
        }

        if (copiedCount > 0) {
          // 标记文件已复制
          await _markFilesCopied();
          // 更新扫描时间
          await _updateLastScanTime();
          print('字典文件复制完成，共复制 $copiedCount 个文件');

          if (failedFiles.isNotEmpty) {
            print('有 ${failedFiles.length} 个文件复制失败: ${failedFiles.join(", ")}');
          }
        } else {
          print('未能成功复制任何字典文件');
          throw Exception('未能成功复制任何字典文件');
        }
      } catch (e) {
        print('加载资源文件失败: $e');
        throw Exception('加载资源文件失败: $e');
      }
    } catch (e) {
      print('复制字典文件时出错: $e');
      rethrow;
    }
  }

  // 检查目录是否为空
  static Future<bool> _isDirectoryNotEmpty(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      return entities.isNotEmpty;
    } catch (e) {
      print('检查目录是否为空时出错: $e');
      return false;
    }
  }

  // 获取字典文件列表
  static Future<List<Map<String, dynamic>>> getDictionaryFiles() async {
    try {
      final dictionaryPath = await getDictionaryPath();
      final directory = Directory(dictionaryPath);

      if (!await directory.exists()) {
        print('字典目录不存在: $dictionaryPath');
        return [];
      }

      // 检查是否需要扫描
      final shouldScan = await _shouldScan();
      if (!shouldScan) {
        print('使用缓存的字典列表');
        // 这里可以实现从缓存获取字典列表的逻辑
        // 暂时先强制扫描
      }

      print('扫描字典目录: $dictionaryPath');
      final List<FileSystemEntity> files = await directory.list().toList();
      final List<Map<String, dynamic>> dictionaries = [];

      for (var file in files) {
        if (file is File && file.path.endsWith('.txt')) {
          final fileSize = await file.length();
          final fileName =
              file.path.split(Platform.isWindows ? '\\' : '/').last;

          // 计算文件大小显示
          String sizeDisplay;
          if (fileSize < 1024 * 1024) {
            sizeDisplay = '${(fileSize / 1024).toStringAsFixed(1)}KB';
          } else {
            sizeDisplay = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
          }

          // 计算字典行数
          String entriesCount = '计算中...';
          try {
            // 对于大文件，不计算行数
            final tenMB = 10 * 1024 * 1024; // 10MB
            if (fileSize > tenMB) {
              entriesCount = '文件太大无法计算';
            } else {
              // 简单估算行数，避免读取大文件
              final lineCount = fileSize ~/ 20; // 假设平均每行20个字符
              entriesCount = '$lineCount';
            }
          } catch (e) {
            print('计算行数失败: $e');
          }

          // 创建字典信息
          dictionaries.add({
            'name': fileName,
            'size': sizeDisplay,
            'entries': entriesCount,
          });
        }
      }

      print('找到 ${dictionaries.length} 个字典文件');

      // 更新扫描时间
      await _updateLastScanTime();
      return dictionaries;
    } catch (e) {
      print('获取字典文件列表失败: $e');
      return [];
    }
  }
}
