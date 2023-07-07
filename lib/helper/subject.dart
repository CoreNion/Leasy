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
}

/// データベースから教科を削除する
Future<int> removeSubject(int id) async {
  // セクションの削除
  final secIDs = await getSectionIDs(id);
  for (var secID in secIDs) {
    await removeSection(id, secID);
  }

  return studyDB.delete("Subjects", where: "id = ?", whereArgs: [id]);
}

/// 教科の名前を変更する
Future<int> renameSubjectName(int id, String newTitle) {
  final updateValues = {"title": newTitle};
  return studyDB
      .update("Subjects", updateValues, where: "id = ?", whereArgs: [id]);
}

/// データベースに保存されている記録を更新する
Future<int> updateSubjectRecord(
    int id, int latestCorrect, int latestIncorrect) {
  final updateValues = {
    "latestCorrect": latestCorrect,
    "latestIncorrect": latestIncorrect
  };
  return studyDB
      .update("Subjects", updateValues, where: "id = ?", whereArgs: [id]);
}
