import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';

class CodSessionStore {
  CodSessionStore._();

  static const _boxName = 'codepal_sessions';
  static Box<CodSession>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<CodSession>(_boxName);
  }

  static List<CodSession> all() {
    final list = _box?.values.toList() ?? <CodSession>[];
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static Future<CodSession> create({
    required String provider,
    required String title,
    required String cwd,
    required String command,
    required List<String> args,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final baseDir = CodSettingsStore.baseDir;
    final logPath = p.join(baseDir, 'sessions', '$id.log');
    final session = CodSession(
      id: id,
      provider: provider,
      title: title,
      cwd: cwd,
      command: command,
      args: args,
      logPath: logPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _box?.put(session.id, session);
    return session;
  }

  static Future<void> put(CodSession session) async {
    session.updatedAt = DateTime.now();
    await _box?.put(session.id, session);
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
  }

  static CodSession? byId(String id) => _box?.get(id);

  static ValueListenable<Box<CodSession>>? listenable() {
    return _box?.listenable();
  }

  static Future<void> ensureDirs() async {
    final dir = Directory(CodSettingsStore.baseDir);
    final sessionDir = Directory(p.join(dir.path, 'sessions'));
    if (!await dir.exists()) await dir.create(recursive: true);
    if (!await sessionDir.exists()) await sessionDir.create(recursive: true);
  }
}
