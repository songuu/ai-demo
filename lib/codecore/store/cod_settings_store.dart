/*
 * @Author: songyu
 * @Date: 2026-01-06 17:27:06
 * @LastEditTime: 2026-01-08 15:47:33
 * @LastEditor: songyu
 */
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

class CodSettingsStore {
  CodSettingsStore._();

  static const _boxName = 'codepal_settings';
  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  static String get baseDir {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    return _box?.get('baseDir', defaultValue: p.join(home, '.codecore')) ??
        p.join(home, '.codecore');
  }

  static Future<void> setBaseDir(String value) async {
    await _box?.put('baseDir', value);
  }

  static String get codexCli =>
      _box?.get('codexCli', defaultValue: 'codex') ?? 'codex';
  static Future<void> setCodexCli(String value) async =>
      _box?.put('codexCli', value);

  static String get claudeCli =>
      _box?.get('claudeCli', defaultValue: 'claude') ?? 'claude';
  static Future<void> setClaudeCli(String value) async =>
      _box?.put('claudeCli', value);

  static String get geminiCli =>
      _box?.get('geminiCli', defaultValue: 'gemini') ?? 'gemini';
  static Future<void> setGeminiCli(String value) async =>
      _box?.put('geminiCli', value);

  static String get skillsMpApiKey =>
      _box?.get('skillsMpApiKey', defaultValue: '') ?? '';
  static Future<void> setSkillsMpApiKey(String value) async =>
      _box?.put('skillsMpApiKey', value.trim());

  static String resolveCli(String provider) {
    switch (provider) {
      case 'codex':
        return codexCli;
      case 'claude':
        return claudeCli;
      case 'gemini':
        return geminiCli;
      default:
        return provider;
    }
  }
}
