import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ohos_utils/flutter_ohos_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool hasNewVersion = false;
  var bundleInfo;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            TextButton(
                onPressed: () {
                  FlutterOhosUtils.gotoAppStore('com.wiki8.hap');
                },
                child: const Text('gotoAppStore')),
            TextButton(
                onPressed: () {
                  FlutterOhosUtils.openSetting('wifi_entry');
                },
                child: const Text('open wifi setting')),
            TextButton(
                onPressed: () async {
                  hasNewVersion = await FlutterOhosUtils.checkUpdate();
                  setState(() {});
                },
                child: Text('check update: $hasNewVersion')),
            TextButton(
                onPressed: () {
                  FlutterOhosUtils.showUpdateDialog();
                },
                child: const Text('show update dialog')),
            TextButton(
                onPressed: () async {
                  bundleInfo = await FlutterOhosUtils.getBundleInfo();
                  setState(() {});
                },
                child: Text('get bundle Info: ${bundleInfo}')),
            TextButton(
              onPressed: () async {
                var file = await rootBundle.load('assets/q8.pdf');
                var ok = await FlutterOhosUtils.saveDocument(
                    '报价单_Q008', 'pdf', file.buffer.asUint8List());
                print('is ok ? $ok');
              },
              child: Text('保存pdf'),
            )
          ],
        ),
      ),
    );
  }
}
