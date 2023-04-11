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
Future<int> createSubject(String title) async {
  int id = DateTime.now().millisecondsSinceEpoch;

  await studyDB.insert(
      "Subjects",
      SubjectInfo(title: title, id: id, latestCorrect: 0, latestIncorrect: 0)
          .toMap());
  return id;
}

/// データベースから教科を削除する
Future<int> removeSubject(int id) async {
  // セクションの削除
  final secIDs = await getSectionIDs(id);
  for (var secID in secIDs) {
    await removeSection(id, secID);
  }

  return studyDB.delete("Subjects", where: "id=$id");
}

/// 教科の名前を変更する
Future<int> renameSubjectName(int id, String newTitle) {
  return studyDB
      .rawUpdate("UPDATE Subjects SET title = '$newTitle' WHERE id = $id;");
}

/// データベースに保存されている記録を更新する
Future<int> updateSubjectRecord(
    int id, int latestCorrect, int latestIncorrect) {
  return studyDB.rawUpdate(
      "UPDATE Subjects SET latestCorrect = $latestCorrect, latestIncorrect = $latestIncorrect WHERE id = $id;");
}
