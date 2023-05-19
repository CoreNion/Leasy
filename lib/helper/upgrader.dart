import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// データベースをアップグレードする関数
Future databaseUpgrader(Database db, int oldVersion, int newVersion) async {
  final batch = db.batch();

  switch (oldVersion) {
    case 3:
      await upgradeV3toV4(db, batch);
      break;
    default:
      break;
  }
}

/// データベースをv3からv4にアップグレードする関数
///
/// - IDの形式をUUIDに変更
Future<void> upgradeV3toV4(Database db, Batch batch) async {
  const needUpgradeTables = ["Subjects", "Sections", "Questions"];

  // 新しいuuidテーブルを作成
  for (var name in needUpgradeTables) {
    await db.execute("ALTER TABLE $name ADD COLUMN uuid TEXT");

    if (name == "Sections") {
      await db.execute("ALTER TABLE $name ADD COLUMN subjectUUID TEXT");
    } else if (name == "Questions") {
      await db.execute("ALTER TABLE $name ADD COLUMN sectionUUID TEXT");
    }
  }

  // テーブル内のIDを更新する関数
  updateID(String table) async {
    late List<Map<String, Object?>> oldIDs;
    if (table == "Sections") {
      oldIDs = await db.query("Sections", columns: ["tableID"]);
    } else {
      oldIDs = await db.query(table, columns: ["id"]);
    }

    for (var oldMap in oldIDs) {
      final idIsTableID = table == "Sections" ? true : false;

      final oldID = idIsTableID ? oldMap["tableID"] : oldMap["id"];
      final newID = const Uuid().v4();

      await db.update(table, {"uuid": newID},
          where: "${idIsTableID ? 'tableID' : 'id'} = ?", whereArgs: [oldID]);

      if (table == "Subjects") {
        await db.update("Sections", {"subjectUUID": newID},
            where: "subjectID = ?", whereArgs: [oldID]);
      } else if (table == "Sections") {
        await db.update("Questions", {"sectionUUID": newID},
            where: "sectionID = ?", whereArgs: [oldID]);
      }
    }
  }

  for (var name in needUpgradeTables) {
    // 各テーブル内のIDを更新
    await updateID(name);

    /*
    // テーブル内の古いIDを削除
    if (name == "Sections") {
      await db.execute("ALTER TABLE $name DROP COLUMN tableID");
      await db.execute("ALTER TABLE $name DROP COLUMN subjectID");
    } else {
      await db.execute("ALTER TABLE $name DROP COLUMN id");
      if (name == "Questions") {
        await db.execute("ALTER TABLE $name DROP COLUMN sectionID");
      }
    } */
  }
}
