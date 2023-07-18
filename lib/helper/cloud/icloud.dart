import 'dart:async';
import 'dart:io';

import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    final completer = Completer();

    final tmpPath = p.join((await getTemporaryDirectory()).path, downloadName);
    await ICloudStorage.download(
        containerId: _containerId,
        destinationFilePath: tmpPath,
        onProgress: (stream) {
          stream.listen((event) {
            if (event >= 1) {
              File(tmpPath).copySync(file.path);
              completer.complete();
            }
          });
        },
        relativePath: downloadName);
    await completer.future;
  }

  static Future<void> deleteCloudFile(String fileName) async {
    await ICloudStorage.delete(
        containerId: _containerId, relativePath: fileName);
  }
}
