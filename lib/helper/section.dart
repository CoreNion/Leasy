import 'common.dart';
import '../class/section.dart';

/// Sections DataBaseにセクションを作成
Future<void> createSection(SectionInfo section) async {
  // セクション一覧にIDなどを記録
  await studyDB.insert("Sections", section.toMap());
}

/// Sections DataBaseから指定された教科に所属しているセクションIDとタイトル/完了率を取得
///
/// 返答形式: {セクションID: {セクションタイトル: 完了率}}
Future<Map<int, MapEntry<String, double>>> getSectionSummaries(
    int subjectID) async {
  // セクション一覧から指定された教科に所属しているセクションIDとタイトルを取得
  final results = await studyDB.query('Sections',
      columns: ["tableID", "title"],
      where: "subjectID = ?",
      whereArgs: [subjectID]);
  final tableIDs = results.map((e) => e["tableID"] as int).toList();

  // セクションごとの完了率を計算
  final List<double> tableRates = List.filled(tableIDs.length, 0);
  for (var id in tableIDs) {
    // 問題一覧から指定されたセクションに所属している問題の生後記録を取得し、正解数を計算
    final results = await studyDB.query('Questions',
        columns: ["latestCorrect"], where: "sectionID = ?", whereArgs: [id]);
    final corrects =
        results.where((element) => element["latestCorrect"] == 1).length;
    // 割合を出す
    tableRates[tableIDs.indexOf(id)] = corrects / results.length;
  }

  // セクションIDとタイトル/完了率をMap/MapEntryで返す
  return {
    for (var id in tableIDs)
      id: MapEntry(results[tableIDs.indexOf(id)]["title"] as String,
          tableRates[tableIDs.indexOf(id)])
  };
}

/// Sections DataBaseから指定された教科に所属しているセクションIDを取得する
Future<List<int>> getSectionIDs(int subjectID) async {
  final results = await studyDB.query('Sections',
      columns: ["tableID"], where: "subjectID = ?", whereArgs: [subjectID]);

  return results.map((e) => e["tableID"] as int).toList();
}

/// TableIDからSection情報を取得
Future<SectionInfo> getSectionData(int tableID) async {
  final sectionsMaps = await studyDB
      .query('Sections', where: "tableID = ?", whereArgs: [tableID]);

  return SectionInfo.tableMapToModel(sectionsMaps.first);
}

/// DataBaseから一致したセクションを削除する
Future<int> removeSection(int subjectID, int id) async {
  // セクション一覧から削除
  return studyDB.delete("Sections",
      where: "subjectID = ? AND tableID = ?", whereArgs: [subjectID, id]);
}

// セクション名を変更
Future<int> renameSectionName(int tableID, String name) {
  final updateValues = {"title": name};
  return studyDB.update("Sections", updateValues,
      where: "tableID = ?", whereArgs: [tableID]);
}

/// 指定されたセクションの概要データの更新
Future<int> updateSectionRecord(int sectionID, String latestStudyMode) {
  final updateValues = {"latestStudyMode": latestStudyMode};
  return studyDB.update("Sections", updateValues,
      where: "tableID = ?", whereArgs: [sectionID]);
}
