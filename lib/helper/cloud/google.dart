// ignore_for_file: library_prefixes

import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as googleSignIn;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:sqlite3/common.dart';
import '../common.dart';
import '../dummy.dart' if (dart.library.js) 'package:sqlite3/wasm.dart';
import 'dummy.dart'
    if (dart.library.js) 'package:googleapis_auth/auth_browser.dart'
    as authBrowser;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import '../../class/cloud.dart';

const _iosEnv = "GOOGLE_CLIENT_ID_IOS";
const _desktopClientID = String.fromEnvironment("GOOGLE_CLIENT_ID_DESKTOP");
const _desktopClientSecret =
    String.fromEnvironment("GOOGLE_CLIENT_SECRET_DESKTOP");
const _webClientID = String.fromEnvironment("GOOGLE_CLIENT_ID_WEB");

googleSignIn.GoogleSignIn? _signIn;
googleSignIn.GoogleSignInAccount? _account;
AuthClient? _authClient;
drive.DriveApi? _driveApi;

/// 残っているアカウント関連の変数をnullにする
void _deleteMemoryData() {
  _signIn = null;
  _account = null;
  _authClient = null;
  _driveApi = null;
}

///  google_sign_inの端末か
bool _gsiSupported() {
  if (kIsWeb) return false;

  return Platform.isIOS || Platform.isAndroid;
}

/// GoogleSignInの初期化
Future<void> _initSignIn() async {
  // google_sign_in非対応端末では何もしない
  if (!(_gsiSupported())) {
    return;
  }

  _signIn ??= googleSignIn.GoogleSignIn(
      clientId: Platform.isIOS && const bool.hasEnvironment(_iosEnv)
          ? const String.fromEnvironment(_iosEnv)
          : null,
      scopes: [drive.DriveApi.driveAppdataScope]);
  if (_signIn == null) {
    throw InitSignInException("Googleサインインの初期化に失敗しました。");
  } else {
    return;
  }
}

/// AuthClientの初期化 (ログインが必要)
Future<AuthClient> _initAuth() async {
  // 既存の情報を使ってログインを行う (google_sign_in)
  if (_gsiSupported()) {
    await _initSignIn();
    if (!(_gsiSupported()) || await _signIn!.isSignedIn() == false) {
      throw SignInException("ログインされていません");
    }

    _account ??= await _signIn!.signInSilently();
    if (_account == null) {
      throw SignInException("アカウント情報がありません、再ログインしてください");
    }
    _authClient ??= await _signIn!.authenticatedClient();
  } else if (kIsWeb) {
    final cred = MyApp.prefs.getString("google_cred");
    if (cred == null) {
      throw SignInException("ログインされていません");
    }

    final credential = authBrowser.AccessCredentials.fromJson(jsonDecode(cred));
    _authClient = authBrowser.authenticatedClient(http.Client(), credential);
  } else {
    // 保存されている認証情報を利用
    final credFile = File(p.join(
        (await getApplicationSupportDirectory()).path, "google_cred.json"));
    if (!credFile.existsSync()) {
      throw SignInException("ログインされていません");
    }

    final credential =
        AccessCredentials.fromJson(jsonDecode(await credFile.readAsString()));
    _authClient = autoRefreshingClient(
        ClientId(_desktopClientID, _desktopClientSecret),
        credential,
        http.Client());
  }

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
    await _initSignIn();

    if (_gsiSupported()) {
      if (await _signIn!.isSignedIn()) {
        // サインイン済みの場合はそれを利用する
        _account = await _signIn!.signInSilently();
        // 何らかの理由でnullの場合はサインインし直す
        _account ??= await _signIn!.signIn();
      } else {
        // 初回サインイン
        _account = await _signIn!.signIn();
      }

      // キャンセル等でサインインできなかった場合はfalseを返す
      if (_account == null) {
        return false;
      }
    } else if (kIsWeb) {
      // Webの場合はGoogle認証を行う
      final cred = await authBrowser
          .requestAccessCredentials(clientId: _webClientID, scopes: [
        "https://www.googleapis.com/auth/drive.appdata",
      ]);
      _authClient = authBrowser.authenticatedClient(http.Client(), cred);

      // 認証情報を保存
      await MyApp.prefs.setString("google_cred", jsonEncode(cred.toJson()));
    } else {
      // Authを取得する (googleapis_auth)
      final refAuth = await clientViaUserConsent(
          ClientId(_desktopClientID, _desktopClientSecret), [
        "https://www.googleapis.com/auth/drive.appdata",
      ], (uri) async {
        await launchUrlString(uri);
      });
      _authClient = refAuth;

      // 認証情報を保存
      final credFile = File(p.join(
          (await getApplicationSupportDirectory()).path, "google_cred.json"));
      await credFile.writeAsString(jsonEncode(refAuth.credentials.toJson()));
    }
    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.google;
    MyApp.prefs.setString("CloudType", "google");

    return true;
  }

  /// Googleアカウントのサインイン状態・データの最終更新時刻を確認する
  static Future<(googleSignIn.GoogleSignInAccount?, DateTime?)>
      checkDataStatus() async {
    if (_gsiSupported()) {
      // ログイン
      await _initSignIn();
      if (await _signIn!.isSignedIn()) {
        _account = await _signIn!.signInSilently();
      } else {
        return (null, null);
      }
    }

    // study.dbの最終更新を確認
    final driveAPI = await _initDriveApi();
    final studyList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            q: "name = 'study.db'",
            $fields: 'files(id, name, createdTime, modifiedTime)'))
        .files;
    if (studyList == null || studyList.isEmpty) {
      return (_account, null);
    } else {
      return (_account, studyList.first.modifiedTime);
    }
  }

  /// Googleアカウントからサインアウトする
  static Future<void> signOut() async {
    await _signIn?.disconnect();
    _deleteMemoryData();

    if (!_gsiSupported()) {
      if (kIsWeb) {
        await MyApp.prefs.remove("google_cred");
      } else {
        final credFile = File(p.join(
            (await getApplicationSupportDirectory()).path, "google_cred.json"));
        if (credFile.existsSync()) {
          await credFile.delete();
        }
      }
    }

    // クラウド同期の設定を保存
    MyApp.cloudType = CloudType.none;
    MyApp.prefs.setString("CloudType", "none");
  }

  /// Googleアカウントから一時的にサインアウトする
  static Future<void> signOutTemporarily() async {
    await _signIn?.signOut();
    _deleteMemoryData();
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

  /// ファイルが存在するか確認する
  static Future<bool> fileExists(String fileName) async {
    final driveAPI = await _initDriveApi();

    // ドライブからファイルを取得
    final fileList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            q: "name = '$fileName'",
            $fields: 'files(id, name, createdTime)'))
        .files;

    return fileList != null && fileList.isNotEmpty;
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

    // ファイルのストリームを作成
    late Stream<List<int>> fileStream;
    late int fileLength;
    if (kIsWeb) {
      // IndexedDbFileSystemでデータベースを開く
      final fs = await IndexedDbFileSystem.open(dbName: "sqflite_databases");
      final vFile = fs.xOpen(Sqlite3Filename("/${file.path}"), 1);

      // データをメモリに展開
      fileLength = vFile.file.xFileSize();
      final data = Uint8List(fileLength);
      vFile.file.xRead(data, 0);

      // メモリからストリームを作成
      fileStream = Stream.value(data);
    } else {
      fileStream = file.openRead();
      fileLength = file.lengthSync();
    }

    if (studyList == null || studyList.isEmpty) {
      // 存在しない場合、ドライブにファイルを新規作成
      await driveAPI.files.create(
        uploadedFile,
        uploadMedia: drive.Media(fileStream, fileLength),
      );
    } else {
      // 存在する場合、そのデータを上書き保存
      // 上書き保存の場合、メタデータは空でOK(むしろ空じゃないとエラー)
      await driveAPI.files.update(
        drive.File(),
        studyList.first.id!,
        uploadMedia: drive.Media(fileStream, fileLength),
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
      if (kIsWeb) {
        // DataBaseが開かれている場合は閉じる
        if (isDbLoaded) {
          await studyDB.close();
          isDbLoaded = false;
        }

        // データをメモリにダウンロード
        List<int> data = [];
        await media!.stream.listen((event) {
          data.addAll(event);
        }).asFuture();

        // IndexedDbFileSystemでデータベースを開き、上書き
        final fs = await IndexedDbFileSystem.open(dbName: "sqflite_databases");
        final vFile = fs.xOpen(Sqlite3Filename("/${file.path}"), 1);
        // 上書き
        vFile.file.xWrite(Uint8List.fromList(data), 0);
      } else {
        await media!.stream.pipe(file.openWrite());
      }
    }
  }

  /// Googleドライブから指定されたファイルを削除する
  static Future<void> deleteCloudFile(String fileName) async {
    final driveAPI = await _initDriveApi();

    // ドライブからファイルを取得
    final fileList = (await driveAPI.files.list(
            spaces: 'appDataFolder',
            q: "name = '$fileName'",
            $fields: 'files(id, name, createdTime)'))
        .files;

    if (fileList == null || fileList.isEmpty) {
      // 存在しない場合はエラー
      throw FileApiException("ファイルが見つかりませんでした");
    } else {
      // 存在する場合は削除
      await driveAPI.files.delete(fileList.first.id!);
    }
  }
}
