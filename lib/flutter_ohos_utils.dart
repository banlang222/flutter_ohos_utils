import 'package:flutter/services.dart';

class FlutterOhosUtils {
  static const channel = MethodChannel('flutter_ohos_utils');

  static Future<dynamic> getBundleInfo() async {
    return await channel.invokeMethod('getBundleInfo');
  }

  static Future<bool> checkUpdate() async {
    return await channel
        .invokeMethod('checkUpdate')
        .catchError((error) => false);
  }

  static Future<bool> showUpdateDialog() async {
    return await channel.invokeMethod('showUpdateDialog');
  }

  static Future<void> gotoAppStore(String? bundleName) async {
    await channel.invokeMethod('gotoAppStore', bundleName);
  }

  ///uri:
  ///wifi_entry
  ///location_manager_settings
  ///privacy_settings_entry
  ///bluetooth_entry
  ///mobile_network_entry
  ///date_and_time
  ///display_settings
  ///systemui_notification_settings
  ///nfc_settings
  ///volume_settings
  ///storage_settings
  ///battery
  static Future<void> openSetting(String? uri) async {
    await channel.invokeMethod('openWant', {
      'bundleName': 'com.huawei.hmos.settings',
      'abilityName': 'com.huawei.hmos.settings.MainAbility',
      'uri': uri
    }).catchError((err) {
      print(err);
    });
  }

  /// Map<String, dynamic> want = {
  ///   "deviceId": "",
  /// "bundleName": "",
  ///   "abilityName": "",
  ///   "moduleName": "",
  ///   "action": "",
  ///   "entities": [],
  ///   "uri": "",
  ///   "type": "",
  ///   "parameters": "",
  ///   "flags": ""
  /// };
  static Future<dynamic> openWant(Map<String, dynamic> want) async {
    return await channel.invokeMethod('openWant', want);
  }
}
