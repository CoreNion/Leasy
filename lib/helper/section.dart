import 'cloud/common.dart';
import 'common.dart';
import '../class/section.dart';

/// Sections DataBaseにセクションを作成
Future<void> createSection(SectionInfo section) async {
  // セクション一覧にIDなどを記録
  await studyDB.insert("Sections", section.toMap());
}

/// Sections DataBaseから指定された教科に所属しているセクション情報を取得する
Future<List<SectionInfo>> getSectionInfos(int subjectID) async {
  // 指定された教科に所属しているセクション情報を取得
  final tableIDs = await getSectionIDs(subjectID);
  final secInfos =
      await Future.wait(tableIDs.map((i) => getSectionData(i)).toList());

  // セクションごとの完了率を計算し、セクション情報を補充
  for (var i = 0; i < secInfos.length; i++) {
    // 問題一覧から指定されたセクションに所属している問題の正答記録を取得し、正解数を計算
    final results = await studyDB.query('Questions',
        columns: ["latestCorrect"],
        where: "sectionID = ?",
        whereArgs: [tableIDs[i]]);
    final corrects =
        results.where((element) => element["latestCorrect"] == 1).length;

    // 割合を適用
    secInfos[i].completionRate = corrects / results.length;
  }

  return secInfos;
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
Future<void> removeSection(int subjectID, int id) async {
  // セクション一覧から削除
  await studyDB.delete("Sections",
      where: "subjectID = ? AND tableID = ?", whereArgs: [subjectID, id]);
  await saveToCloud();
}

// セクション名を変更
Future<void> renameSectionName(int tableID, String name) async {
  final updateValues = {"title": name};
  await studyDB.update("Sections", updateValues,
      where: "tableID = ?", whereArgs: [tableID]);
  await saveToCloud();
}

/// 指定されたセクションの概要データの更新
Future<void> updateSectionRecord(int sectionID, String latestStudyMode) async {
  final updateValues = {"latestStudyMode": latestStudyMode};
  await studyDB.update("Sections", updateValues,
      where: "tableID = ?", whereArgs: [sectionID]);
  await saveToCloud();
}
