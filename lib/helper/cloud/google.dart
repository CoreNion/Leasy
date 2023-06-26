// ignore_for_file: library_prefixes, depend_on_referenced_packages

import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as googleSignIn;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

import '../../main.dart';
import '../../class/cloud.dart';

const _iosEnv = "GOOGLE_CLIENT_ID_IOS";

googleSignIn.GoogleSignIn? _signIn;
googleSignIn.GoogleSignInAccount? _account;
AuthClient? _authClient;
drive.DriveApi? _driveApi;

/// GoogleSignInの初期化
Future<googleSignIn.GoogleSignIn> _initSignIn() async {
  _signIn ??= googleSignIn.GoogleSignIn(
      clientId: Platform.isIOS && const bool.hasEnvironment(_iosEnv)
          ? const String.fromEnvironment(_iosEnv)
          : null,
      scopes: [drive.DriveApi.driveAppdataScope]);
  if (_signIn == null) {
    throw InitSignInException("Googleサインインの初期化に失敗しました。");
  } else {
    return _signIn!;
  }
}

/// AuthClientの初期化 (ログインが必要)
Future<AuthClient> _initAuth() async {
  // 既存の情報を使ってログインを行う
  final s = await _initSignIn();
  if (await s.isSignedIn() == false) {
    throw SignInException("ログインされていません");
  }
  _account ??= await s.signInSilently();
  if (_account == null) {
    throw SignInException("アカウント情報がありません、再ログインしてください");
  }

  _authClient ??= await s.authenticatedClient();
  if (_authClient == null) {
    throw AuthException("AuthClientの初期化に失敗しました");
  } else {
    return _authClient!;
  }
}

/// DriveApiの初期化 (ログインが必要)
Future<drive.DriveApi> _initDriveApi() async {
  _driveApi ??= drive.DriveApi(await _initAuth());
  if (_driveApi == null) {
    throw FileApiException("DriveApiの初期化に失敗しました");
  } else {
    return _driveApi!;
  }
}

/// Google系の処理をまとめたクラス
class MiGoogleService {
  /// Googleアカウントにサインインする
  static Future<bool> signIn() async {
    // 初期化
    final s = await _initSignIn();

    if (await s.isSignedIn()) {
      // サインイン済みの場合はそれを利用する
      _account = await s.signInSilently();
      // 何らかの理由でnullの場合はサインインし直す
      _account ??= await s.signIn();
    } else {
      // 初回サインイン
      _account = await s.signIn();
    }

    // キャンセル等でサインインできなかった場合はfalseを返す
    if (_account == null) {
      return false;
    } else {
      // クラウド同期の設定を保存
      MyApp.cloudType = CloudType.google;
      MyApp.prefs.setString("CloudType", "google");

      return true;
    }
  }

  /// Googleアカウントのサインイン状態を確認する
  static Future<googleSignIn.GoogleSignInAccount?> checkLoginStatus() async {
    final s = await _initSignIn();

    if (await s.isSignedIn()) {
      _account = await s.signInSilently();
    } else {
      return null;
    }
    return _account!;
  }

  /// Googleアカウントからサインアウトする
  static Future<void> signOut() async {
    if (_signIn == null) {
      throw InitSignInException("Googleサインインが初期化されていません");
    }
    await _signIn!.disconnect();

    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.none;
    MyApp.prefs.setString("CloudType", "none");
  }

  /// Googleドライブからアプリ内ファイル一覧を取得する
  static Future<List<drive.File>?> getAppDriveFiles() async {
    final driveAPI = await _initDriveApi();

    // ドライブからファイル一覧を取得
    final studyList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            $fields: 'files(id, name, createdTime, modifiedTime)'))
        .files;

    return studyList;
  }

  /// Googleドライブに指定されたファイルをアップロードする
  static Future<void> uploadToAppFolder(String uploadName, File file) async {
    final driveAPI = await _initDriveApi();

    // アップロード用のメタデータを構築
    final uploadedFile = drive.File();
    uploadedFile.parents = ["appDataFolder"];
    uploadedFile.name = uploadName;

    // ドライブに既存のファイルが存在するか確認
    final studyList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            q: "name = '$uploadName'",
            $fields: 'files(id, name, createdTime)'))
        .files;
    if (studyList == null || studyList.isEmpty) {
      // 存在しない場合、ドライブにファイルを新規作成
      await driveAPI.files.create(
        uploadedFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );
    } else {
      // 存在する場合、そのデータを上書き保存
      // 上書き保存の場合、メタデータは空でOK(むしろ空じゃないとエラー)
      await driveAPI.files.update(
        drive.File(),
        studyList.first.id!,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );
    }
  }

  /// Googleドライブから指定されたファイルをダウンロードする
  static Future<void> downloadFromAppFolder(
      String downloadName, File file) async {
    final driveAPI = await _initDriveApi();

    // ドライブからファイルを取得
    final fileList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            q: "name = '$downloadName'",
            $fields: 'files(id, name, createdTime)'))
        .files;

    if (fileList == null || fileList.isEmpty) {
      // 存在しない場合はエラー
      throw FileApiException("ファイルが見つかりませんでした");
    } else {
      // 存在する場合はダウンロード
      final media = await driveAPI.files.get(fileList.first.id!,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media?;
      await media!.stream.pipe(file.openWrite());
    }
  }
}
