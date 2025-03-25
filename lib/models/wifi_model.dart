class WiFiNetwork {
  final String name;
  final String encryption;
  int signal;
  bool isSelected;

  // 添加新属性
  final String? bssid; // MAC地址
  final String? frequency; // 频率
  final String? channel; // 信道
  final String? standard; // WiFi标准(WiFi4/WiFi5/WiFi6)
  final String? band; // 频段(2.4G/5G/6G)
  String? password; // 连接密码
  bool isConnected; // 是否已连接

  WiFiNetwork({
    required this.name,
    required this.encryption,
    required this.signal,
    this.isSelected = false,
    this.bssid,
    this.frequency,
    this.channel,
    this.standard,
    this.band,
    this.password,
    this.isConnected = false,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      name: json['name'] as String,
      encryption: json['encryption'] as String,
      signal: json['signal'] as int,
      isSelected: json['isSelected'] as bool? ?? false,
      bssid: json['bssid'] as String?,
      frequency: json['frequency'] as String?,
      channel: json['channel'] as String?,
      standard: json['standard'] as String?,
      band: json['band'] as String?,
      password: json['password'] as String?,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'encryption': encryption,
      'signal': signal,
      'isSelected': isSelected,
      'bssid': bssid,
      'frequency': frequency,
      'channel': channel,
      'standard': standard,
      'band': band,
      'password': password,
      'isConnected': isConnected,
    };
  }
}

class CrackingStatus {
  final String wifiName;
  final String dictionaryName;
  final String dictionarySize;
  final String estimatedTime;
  final String currentProgress;
  final double progressPercent;

  CrackingStatus({
    required this.wifiName,
    required this.dictionaryName,
    required this.dictionarySize,
    required this.estimatedTime,
    required this.currentProgress,
    required this.progressPercent,
  });
}

class WiFiHistory {
  final String ssid;
  final String password;
  final DateTime date;
  final String encryption;
  final int signalStrength;

  WiFiHistory({
    required this.ssid,
    required this.password,
    required this.date,
    required this.encryption,
    required this.signalStrength,
  });

  factory WiFiHistory.fromJson(Map<String, dynamic> json) {
    return WiFiHistory(
      ssid: json['ssid'] as String,
      password: json['password'] as String,
      date: DateTime.parse(json['date'] as String),
      encryption: json['encryption'] as String,
      signalStrength: json['signalStrength'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
      'date': date.toIso8601String(),
      'encryption': encryption,
      'signalStrength': signalStrength,
    };
  }
}

class Dictionary {
  final String name;
  final String size;
  final String entries;
  bool selected;

  Dictionary({
    required this.name,
    required this.size,
    required this.entries,
    this.selected = false,
  });

  factory Dictionary.fromJson(Map<String, dynamic> json) {
    return Dictionary(
      name: json['name'] as String,
      size: json['size'] as String,
      entries: json['entries'] as String,
      selected: json['selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'entries': entries,
      'selected': selected,
    };
  }
}

// 添加WiFi破解结果记录类
class WiFiCrackResult {
  final String ssid; // WiFi名称
  final String? device; // WiFi设备
  final String? bssid; // MAC地址
  final String? channel; // 信道
  final String? ap; // AP
  final String encryptionType; // 密码类型
  final String password; // 破解的密码
  final DateTime crackTime; // 破解时间
  final String? band; // 频段
  final String? standard; // WiFi标准

  WiFiCrackResult({
    required this.ssid,
    this.device,
    this.bssid,
    this.channel,
    this.ap,
    required this.encryptionType,
    required this.password,
    required this.crackTime,
    this.band,
    this.standard,
  });

  factory WiFiCrackResult.fromJson(Map<String, dynamic> json) {
    return WiFiCrackResult(
      ssid: json['ssid'] as String,
      device: json['device'] as String?,
      bssid: json['bssid'] as String?,
      channel: json['channel'] as String?,
      ap: json['ap'] as String?,
      encryptionType: json['encryptionType'] as String,
      password: json['password'] as String,
      crackTime: DateTime.parse(json['crackTime'] as String),
      band: json['band'] as String?,
      standard: json['standard'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'device': device,
      'bssid': bssid,
      'channel': channel,
      'ap': ap,
      'encryptionType': encryptionType,
      'password': password,
      'crackTime': crackTime.toIso8601String(),
      'band': band,
      'standard': standard,
    };
  }
}
