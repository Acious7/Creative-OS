import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SmtpConfig {
  final String senderName;
  final String senderEmail;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool isSsl;

  SmtpConfig({
    required this.senderName,
    required this.senderEmail,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.isSsl = true,
  });

  Map<String, dynamic> toJson() => {
    'senderName': senderName,
    'senderEmail': senderEmail,
    'host': host,
    'port': port,
    'username': username,
    'password': password,
    'isSsl': isSsl,
  };

  factory SmtpConfig.fromJson(Map<String, dynamic> json) => SmtpConfig(
    senderName: json['senderName'] as String? ?? '',
    senderEmail: json['senderEmail'] as String? ?? '',
    host: json['host'] as String? ?? 'smtp.gmail.com',
    port: json['port'] as int? ?? 465,
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    isSsl: json['isSsl'] as bool? ?? true,
  );
}

class SmtpStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'etole_smtp_settings';

  static Future<void> saveConfig(SmtpConfig config) async {
    await _storage.write(key: _key, value: jsonEncode(config.toJson()));
  }

  static Future<SmtpConfig?> loadConfig() async {
    final str = await _storage.read(key: _key);
    if (str == null) return null;
    try {
      return SmtpConfig.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }
}
