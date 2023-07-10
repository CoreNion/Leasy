import 'cloud/common.dart';
import 'common.dart';
import '../class/subject.dart';
import './section.dart';

/// データベースにある教科を取得する
Future<List<SubjectInfo>> getSubjectInfos() async {
  final subInfoMaps = await studyDB.query('Subjects');

  List<SubjectInfo> subInfos = [];
  for (var subInfo in subInfoMaps) {
    subInfos.add(SubjectInfo.tableMapToModel(subInfo));
  }
  return subInfos;
}

/// データベースに教科を作成する
Future<void> createSubject(SubjectInfo subInfo) async {
  await studyDB.insert("Subjects", subInfo.toMap());
  await saveToCloud();
}

/// データベースから教科を削除する
Future<void> removeSubject(int id) async {
  // セクションの削除
  final secIDs = await getSectionIDs(id);
  for (var secID in secIDs) {
    await removeSection(id, secID);
  }
  await studyDB.delete("Subjects", where: "id = ?", whereArgs: [id]);

  await saveToCloud();
}

/// 教科の名前を変更する
Future<void> renameSubjectName(int id, String newTitle) async {
  final updateValues = {"title": newTitle};
  await studyDB
      .update("Subjects", updateValues, where: "id = ?", whereArgs: [id]);

  await saveToCloud();
}

/// データベースに保存されている記録を更新する
Future<void> updateSubjectRecord(
    int id, int latestCorrect, int latestIncorrect) async {
  final updateValues = {
    "latestCorrect": latestCorrect,
    "latestIncorrect": latestIncorrect
  };
  await studyDB
      .update("Subjects", updateValues, where: "id = ?", whereArgs: [id]);

  await saveToCloud();
}
