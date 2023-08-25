// ignore_for_file: duplicate_import

import 'dart:io' as io;
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqlite3/common.dart';

import '../class/cloud.dart';
import '../main.dart';
import 'cloud/common.dart';
import 'dummy.dart' if (dart.library.js) 'dart:js';
import 'dummy.dart' if (dart.library.html) 'dart:html';
import 'dummy.dart' if (dart.library.js) 'package:sqlite3/wasm.dart';

late Database studyDB;
bool isDbLoaded = false;

/// データベースのデフォルトのパスを取得する関数
Future<String> getDataBasePath() async {
  if (kIsWeb) {
    return "study.db";
  } else {
    final path = (await getApplicationSupportDirectory()).path;
    return p.join(path, "study.db");
  }
}

/// データベースを読み込み・作成する関数
Future<void> loadStudyDataBase() async {
  final options = OpenDatabaseOptions(
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE Subjects(title text, id integer primary key autoincrement, latestCorrect int, latestIncorrect int)");
        await db.execute(
            "CREATE TABLE Sections(subjectID int, title text, tableID integer primary key autoincrement, latestStudyMode text)");
        await db.execute(
            "CREATE TABLE Questions(id integer primary key autoincrement, sectionID int, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int, latestCorrect int, totalCorrect int, totalInCorrect int)");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        switch (oldVersion) {
          case 3:
            // 合計正解数・不正解数を追加
            await db.execute(
                "ALTER TABLE Questions ADD COLUMN totalCorrect int DEFAULT 0");
            await db.execute(
                "ALTER TABLE Questions ADD COLUMN totalInCorrect int DEFAULT 0");
            break;
          default:
            break;
        }
      },
      version: 4);

  final dbPath = await getDataBasePath();

  if (!(MyApp.cloudType == CloudType.none)) {
    // クラウドのstudy.dbをダウンロード
    final file = io.File(dbPath);
    await CloudService.downloadFile("study.db", file);
  }

  // データベースを開く
  if (kIsWeb) {
    studyDB =
        await databaseFactoryFfiWeb.openDatabase(dbPath, options: options);
  } else {
    studyDB = await databaseFactoryFfi.openDatabase(dbPath, options: options);
  }

  isDbLoaded = true;
}

/// データベースを削除する関数
Future<void> deleteStudyDataBase() async {
  // DataBaseが開かれている場合は閉じる
  if (isDbLoaded) {
    await studyDB.close();
    isDbLoaded = false;
  }

  if (!kIsWeb) {
    final file = io.File(
        (p.join((await getApplicationSupportDirectory()).path, "study.db")));
    await file.delete();
  } else {
    await context["indexedDB"]
        .callMethod("deleteDatabase", ["sqflite_databases"]);
  }
}

/// データベースをバックアップする関数
Future<bool> backupDataBase() async {
  bool result = true;
  final path = await getDataBasePath();

  // 保存処理
  if (kIsWeb) {
    // study.dbが入っているIndexedDbFileSystemをロード
    final fs = await IndexedDbFileSystem.open(dbName: "sqflite_databases");
    // ファイルを開く
    final file = fs.xOpen(Sqlite3Filename("/study.db"), 1);

    // study.dbの生データを取得し、ダウンロードさせる
    final data = Uint8List(file.file.xFileSize());
    file.file.xRead(data, 0);

    AnchorElement(
        href:
            "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(data)}")
      ..setAttribute("download", "study.db")
      ..click();
  } else {
    if (io.Platform.isIOS || io.Platform.isAndroid) {
      final res = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(sourceFilePath: path));
      if (res == null) result = false;
    } else {
      final savePath = await FilePicker.platform.saveFile(
          lockParentWindow: true,
          fileName: "stydy.db",
          dialogTitle: "保存先を選択",
          allowedExtensions: ["db"]);
      if (savePath == null) {
        result = false;
      } else {
        await io.File(path).copy(savePath);
      }
    }
  }

  return result;
}

// データベースをインポートする関数 (Web版は非対応)
Future<bool> importDataBase() async {
  // ファイル選択
  final res = await FilePicker.platform
      .pickFiles(type: FileType.any, lockParentWindow: true);
  if (res == null) return false;
  final pFile = res.files.first;

  if (kIsWeb) {
    // DataBaseが開かれている場合は閉じる
    if (isDbLoaded) {
      await studyDB.close();
      isDbLoaded = false;
    }

    // Web版ではloadStudyDataBase()で再読み込みできないため、ヘッダーからデータベースかを判定
    final dataHeader = pFile.bytes!.sublist(0, 16);
    // https://www.sqlite.org/fileformat.html
    // "SQLite format 3\000"
    final correctHeader = Uint8List.fromList([
      83,
      81,
      76,
      105,
      116,
      101,
      32,
      102,
      111,
      114,
      109,
      97,
      116,
      32,
      51,
      0
    ]);
    // データを比較し、ダメならFormatExceptionを投げる
    if (!listEquals(dataHeader, correctHeader)) {
      // indexedDB削除
      deleteStudyDataBase();
      // 新規作成
      await loadStudyDataBase();

      throw const FormatException("通常のデータベースファイルとは異なるデータが検知されました。");
    }

    // IndexedDbFileSystemでデータベースをを開く
    final fs = await IndexedDbFileSystem.open(dbName: "sqflite_databases");
    final file = fs.xOpen(Sqlite3Filename("/study.db"), 1);
    // 上書き
    file.file.xWrite(pFile.bytes!, 0);
  } else {
    // 既存ファイル削除
    await deleteStudyDataBase();

    final path = (await getApplicationSupportDirectory()).path;
    await io.File(pFile.path!).copy(p.join(path, "study.db"));
  }

  // データベースの再読み込み
  await loadStudyDataBase().catchError((e) async {
    // ファイル削除
    deleteStudyDataBase();
    // 新規作成
    await loadStudyDataBase();

    throw e;
  });
  return true;
}

/// データベースファイルにデモファイルを利用する関数
Future<void> useDemoFile() async {
  // データベースが開かれている場合は閉じる
  if (isDbLoaded) {
    await studyDB.close();
    isDbLoaded = false;
  }
  // デモファイルを読み込む
  final data = (await rootBundle.load('assets/demo.db')).buffer.asUint8List();

  if (kIsWeb) {
    // IndexedDbFileSystemでデータベースをを開く
    final fs = await IndexedDbFileSystem.open(dbName: "sqflite_databases");
    final file = fs.xOpen(Sqlite3Filename("/study.db"), 1);
    // 上書き
    file.file.xWrite(data, 0);
  } else {
    // 既存ファイル削除
    await deleteStudyDataBase();

    // デモファイルをコピー
    final path = (await getApplicationSupportDirectory()).path;
    await io.File(p.join(path, "study.db")).writeAsBytes(data);
  }

  // データベースを再読み込み
  await loadStudyDataBase();
}
