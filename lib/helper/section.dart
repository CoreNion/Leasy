import 'common.dart';
import '../class/section.dart';

/// Sections DataBaseにセクションを作成
Future<SectionInfo> createSection(int subjectID, String title) async {
  int tableID = DateTime.now().millisecondsSinceEpoch;
  final section = SectionInfo(
      subjectID: subjectID,
      title: title,
      tableID: tableID,
      latestStudyMode: "no");

  // セクション一覧にIDなどを記録
  await studyDB.insert("Sections", section.toMap());
  return section;
}

/// Sections DataBaseから指定された教科に所属しているセクションIDとタイトルを取得する
Future<Map<int, String>> getSectionSummaries(int subjectID) async {
  final results = await studyDB.query('Sections',
      columns: ["tableID", "title"],
      where: "subjectID = ?",
      whereArgs: [subjectID]);

  return {for (var e in results) e["tableID"] as int: e["title"] as String};
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
