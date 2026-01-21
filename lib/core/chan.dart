import 'dart:io';

import 'package:flutter/services.dart';
import 'package:server_box/data/res/misc.dart';

abstract final class MethodChans {
  static const _channel = MethodChannel('${Miscs.pkgName}/main_chan');

  /// 检查是否支持 platform channel 调用（仅 Android/iOS）
  static bool get _supportsMobileChannel =>
      Platform.isAndroid || Platform.isIOS;

  static void moveToBg() {
    if (!_supportsMobileChannel) return;
    _channel.invokeMethod('sendToBackground');
  }

  /// Issue #662
  static void startService() {
    // if (Stores.setting.fgService.fetch() != true) return;
    // _channel.invokeMethod('startService');
  }

  /// Issue #662
  static void stopService() {
    // if (Stores.setting.fgService.fetch() != true) return;
    // _channel.invokeMethod('stopService');
  }

  static void updateHomeWidget() async {
    // 桌面小部件仅支持 Android
    if (!Platform.isAndroid) return;
    //if (!Stores.setting.autoUpdateHomeWidget.fetch()) return;
    await _channel.invokeMethod('updateHomeWidget');
  }
}
