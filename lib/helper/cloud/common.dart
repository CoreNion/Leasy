import 'dart:io';

import '../../class/cloud.dart';
import '../../main.dart';
import '../common.dart';

import 'google.dart';
import 'icloud.dart';

/// クラウドが設定されている場合、直ちに学習データを保存する関数
Future<void> saveToCloud() async {
  final cloudType = MyApp.cloudType;

  if (cloudType != CloudType.none) {
    final file = File(studyDB.path);
    return CloudService.uploadFile("study.db", file);
  }
}

class CloudService {
  /// 接続中のクラウドの情報を取得する
  static Future<CloudAccountInfo> getCloudInfo() async {
    final cloudType = MyApp.cloudType;
    if (cloudType == CloudType.google) {
      final info = await MiGoogleService.checkLoginStatus();
      if (info != null) {
        return CloudAccountInfo(type: CloudType.google, email: info.email);
      } else {
        return CloudAccountInfo(type: CloudType.none, email: null);
      }
    } else if (cloudType == CloudType.icloud) {
      return CloudAccountInfo(type: CloudType.icloud, email: null);
    } else {
      return CloudAccountInfo(type: CloudType.none, email: null);
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
}
