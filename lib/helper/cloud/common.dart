import 'dart:io';

import 'package:flutter/material.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../../class/cloud.dart';
import '../../main.dart';
import '../common.dart';

import 'google.dart';
import 'icloud.dart';

/// エラーが発生したときに表示するダイアログ
Future<void> _showErrorDialog(
    Object e, String message, Future<void> Function() retry) async {
  late String m;
  bool relogin = false;

  if (e is AccessDeniedException || e is AuthException) {
    m = "クラウドへのアクセスが拒否されました。再ログインが必要です。\n詳細: $e";
    relogin = true;
  } else if (e is SocketException || e is http.ClientException) {
    m = "サーバー接続時にエラーが発生しました。\nインターネット環境を確認してください。\n詳細: $e";
  } else {
    m = "不明なエラーが発生しました。\n詳細: $e";
  }

  bool loading = false;
  return showDialog(
      context: MyApp.navigatorKey.currentContext!,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("エラー"),
            content: Text(m),
            actions: [
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                        });

                        if (relogin) {
                          await CloudService.signOutTemporarily();
                          await CloudService.signIn(MyApp.cloudType);
                        }
                        await retry();

                        Navigator.pop(context);
                      },
                child: loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: colorScheme.onSurface,
                          strokeWidth: 3,
                        ))
                    : const Text("再試行"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("閉じる"),
              ),
            ],
          );
        });
      });
}

/// クラウドが設定されている場合、直ちに学習データを保存する関数
Future<void> saveToCloud() async {
  final cloudType = MyApp.cloudType;

  if (cloudType != CloudType.none) {
    final file = File(await getDataBasePath());

    try {
      await CloudService.uploadFile("study.db", file);
    } catch (e) {
      await _showErrorDialog(e, "クラウドへの保存に失敗しました。", saveToCloud);
    }
  }
}

class CloudService {
  /// 接続中のクラウドの情報を取得する
  static Future<CloudAccountInfo> getCloudInfo() async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      final info = await MiGoogleService.checkDataStatus();
      if (info != (null, null)) {
        return CloudAccountInfo(
            type: CloudType.google,
            email: info.$1?.email,
            lastSyncTime: info.$2);
      } else if (info.$2 == null) {
        return CloudAccountInfo(
            type: CloudType.google, email: info.$1?.email, lastSyncTime: null);
      } else {
        return CloudAccountInfo(type: CloudType.none);
      }
    } else if (cloudType == CloudType.icloud) {
      return CloudAccountInfo(
          type: CloudType.icloud, email: null, lastSyncTime: null);
    } else {
      return CloudAccountInfo(type: CloudType.none);
    }
  }

  /// クラウドに初回サインインする
  static Future<bool> signIn(CloudType cloudType) async {
    if (cloudType == CloudType.google) {
      return await MiGoogleService.signIn();
    } else if (cloudType == CloudType.icloud) {
      return await MiiCloudService.signIn();
    } else {
      return false;
    }
  }

  /// 接続されているクラウドからサインアウトする
  static Future<void> signOut() async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.signOut();
    } else if (cloudType == CloudType.icloud) {
      await MiiCloudService.signOut();
    }
  }

  /// 接続されているクラウドから一時的にサインアウトする
  static Future<void> signOutTemporarily() async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.signOutTemporarily();
    }
  }

  /// 指定されたファイルを、接続されているクラウドのアプリ用フォルダーにアップロードする
  static Future<void> uploadFile(String uploadName, File file) async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.uploadToAppFolder(uploadName, file);
    } else if (cloudType == CloudType.icloud) {
      await MiiCloudService.uploadFile(uploadName, file);
    }
  }

  /// 指定されたファイルを、接続されているクラウドのアプリ用フォルダーからダウンロードする
  static Future<void> downloadFile(String downloadName, File file) async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.downloadFromAppFolder(downloadName, file);
    } else if (cloudType == CloudType.icloud) {
      await MiiCloudService.downloadFile(downloadName, file);
    }
  }

  /// 指定されたファイルを削除する
  static Future<void> deleteCloudFile(String fileName) async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.deleteCloudFile(fileName);
    } else if (cloudType == CloudType.icloud) {
      await MiiCloudService.deleteCloudFile(fileName);
    }
  }

  /// leasy関連のファイルを削除
  static Future<void> deleteLeasyFiles() async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      await MiGoogleService.deleteCloudFile("study.db");
    } else if (cloudType == CloudType.icloud) {
      await MiGoogleService.deleteCloudFile("study.db");
    }
  }

  /// ファイルが存在するか確認する
  static Future<bool> fileExists(String fileName) async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      return await MiGoogleService.fileExists(fileName);
    } else if (cloudType == CloudType.icloud) {
      return await MiiCloudService.fileExists(fileName);
    } else {
      return false;
    }
  }
}
