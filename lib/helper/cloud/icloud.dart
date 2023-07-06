import 'dart:io';

import 'package:icloud_storage/icloud_storage.dart';

import '../../class/cloud.dart';
import '../../main.dart';

const _containerId = String.fromEnvironment("ICLOUD_CONTAINER_ID");

class MiiCloudService {
  /// iCloudにログインする
  static Future<bool> signIn() async {
    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.icloud;
    MyApp.prefs.setString("CloudType", "icloud");

    return true;
  }

  /// iCloudからサインアウトする
  static Future<void> signOut() async {
    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.none;
    MyApp.prefs.setString("CloudType", "none");
  }

  static Future<void> uploadFile(String uploadName, File file) async {
    await ICloudStorage.upload(containerId: _containerId, filePath: file.path);
  }

  static Future<void> downloadFile(String downloadName, File file) async {
    await ICloudStorage.download(
        containerId: _containerId,
        destinationFilePath: file.path,
        relativePath: downloadName);
  }
}
