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
    // 正常に動作するかのチェック
    final tmpPath = (await getTemporaryDirectory()).path;
    File(p.join(tmpPath, "test")).writeAsStringSync("test0423");

    // アップロードテスト
    await MiiCloudService.uploadFile("test", File(p.join(tmpPath, "test")));
    // ダウンロードテスト
    await MiiCloudService.downloadFile("test", File(p.join(tmpPath, "test2")));
    // 削除
    await MiiCloudService.deleteCloudFile("test");

    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.icloud;
    await MyApp.prefs.setString("CloudType", "icloud");

    return true;
  }

  /// iCloudからサインアウトする
  static Future<void> signOut() async {
    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.none;
    await MyApp.prefs.setString("CloudType", "none");
  }

  /// iCloudにファイルをアップロードする
  static Future<void> uploadFile(String uploadName, File file) async {
    final completer = Completer();

    await ICloudStorage.upload(
      containerId: _containerId,
      filePath: file.path,
      onProgress: (stream) {
        stream.listen((event) {
          if (event >= 1) {
            completer.complete();
          }
        });
      },
    );
    await completer.future;
  }

  /// iCloudからファイルをダウンロードする
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

  /// iCloudのファイルを削除する
  static Future<void> deleteCloudFile(String fileName) async {
    await ICloudStorage.delete(
        containerId: _containerId, relativePath: fileName);
  }
}
