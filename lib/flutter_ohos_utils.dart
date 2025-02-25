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

  static Future<String> saveDocument(
      String fileName, String fileExt, Uint8List fileBytes) async {
    return await channel.invokeMethod('saveDocument', {
      'fileName': fileName,
      'fileExt': fileExt,
      'fileBytes': fileBytes
    }).catchError((error) {
      print('err=$error');
    });
  }

  ///application/pdf
  ///text/plain、text/x-c++src、text/x-csrc、text/x-chdr、text/x-java、application/xhtml+xml、text/xml、
  ///text/html
  ///image/jpeg、image/png、image/gif、image/webp，image/bmp、image/svg+xml
  ///audio/mp4a-latm、audio/aac、audio/mpeg、audio/ogg、audio/x-wav
  ///video/mp4、video/x-matroska、video/mp2ts
  ///application/msword、application/vnd.openxmlformats-officedocument.wordprocessingml.document、application/vnd.ms-excel、application/vnd.openxmlformats-officedocument.spreadsheetml.sheet、application/vnd.ms-powerpoint、application/vnd.openxmlformats-officedocument.presentationml.presentation、text/comma-separated-values
  static Future<bool> previewFile(
      String title, String path, String mimeType) async {
    return await channel.invokeMethod(
        'previewFile', {'title': title, 'path': path, 'mimeType': mimeType});
  }
}
