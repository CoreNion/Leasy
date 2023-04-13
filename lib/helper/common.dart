import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dummy.dart' if (dart.library.js) 'dart:js';

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
    final file = File(
        (p.join((await getApplicationSupportDirectory()).path, "study.db")));
    await file.delete();
  } else {
    await context["indexedDB"]
        .callMethod("deleteDatabase", ["sqflite_databases"]);
  }
}
