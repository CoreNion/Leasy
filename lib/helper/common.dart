import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js';

late Database studyDB;

/// データベースを読み込み・作成する関数
Future<void> loadStudyDataBase() async {
  final options = OpenDatabaseOptions(
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE Subjects(title text, latestCorrect int, latestIncorrect int)");
        await db.execute(
            "CREATE TABLE Sections(subject text, title text, tableID integer primary key autoincrement, latestStudyMode text)");
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
    final file = File(
        (p.join((await getApplicationSupportDirectory()).path, "study.db")));
    await file.delete();
  } else {
    await context.callMethod("indexedDB.deleteDatabase", ["sqflite_databases"]);
  }
}
