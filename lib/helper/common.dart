import 'dart:io' as io;
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dummy.dart' if (dart.library.js) 'dart:js';
import 'dummy.dart' if (dart.library.html) 'dart:html';
import 'dummy.dart'
    if (dart.library.js) 'package:sqlite3/src/wasm/file_system/indexed_db.dart';

late Database studyDB;

/// データベースを読み込み・作成する関数
Future<void> loadStudyDataBase() async {
  final options = OpenDatabaseOptions(
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE Subjects(title text, id integer primary key autoincrement, latestCorrect int, latestIncorrect int)");
        await db.execute(
            "CREATE TABLE Sections(subjectID int, title text, tableID integer primary key autoincrement, latestStudyMode text)");
        await db.execute(
            "CREATE TABLE Questions(id integer primary key autoincrement, sectionID int, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int, latestCorrect int)");
      },
      version: 3);

  if (kIsWeb) {
    studyDB =
        await databaseFactoryFfiWeb.openDatabase("study.db", options: options);
  } else {
    final path = (await getApplicationSupportDirectory()).path;
    studyDB = await databaseFactoryFfi.openDatabase(p.join(path, "study.db"),
        options: options);
  }
}

/// データベースを削除する関数
Future<void> deleteStudyDataBase() async {
  // DataBaseが開かれている場合は閉じる
  if (studyDB.isOpen) {
    await studyDB.close();
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
  final path = studyDB.path;
  bool result = true;
  // DataBaseが開かれている場合は閉じる
  if (studyDB.isOpen) {
    await studyDB.close();
  }

  // 保存処理
  if (kIsWeb) {
    // study.dbが入っているIndexedDbFileSystemをロード
    final fs = AsynchronousIndexedDbFileSystem("sqflite_databases");
    await fs.open();

    // study.dbの生データを取得し、ダウンロードさせる
    final data = await fs.readFully((await fs.fileIdForPath("/study.db"))!);
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

  // データベースの再読み込み
  await loadStudyDataBase();
  return result;
}
