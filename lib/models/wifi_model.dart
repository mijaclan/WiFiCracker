class WiFiNetwork {
  final String name;
  final String encryption;
  final int signal;
  bool isSelected;

  WiFiNetwork({
    required this.name,
    required this.encryption,
    required this.signal,
    this.isSelected = false,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      name: json['name'] as String,
      encryption: json['encryption'] as String,
      signal: json['signal'] as int,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'encryption': encryption,
      'signal': signal,
      'isSelected': isSelected,
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