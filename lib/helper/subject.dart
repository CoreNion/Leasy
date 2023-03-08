import 'common.dart';
import '../class/subject.dart';

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
  return studyDB.insert("Subjects",
      SubjectInfo(title: title, latestCorrect: 0, latestIncorrect: 0).toMap());
}

/// データベースから教科を削除する
Future<int> removeSubject(String title) async {
  return studyDB.delete("Subjects", where: "title='$title'");
}

/// データベースに保存されている記録を更新する
Future<int> updateSubjectRecord(
    String title, int latestCorrect, int latestIncorrect) {
  return studyDB.rawUpdate(
      "UPDATE Subjects SET latestCorrect = $latestCorrect, latestIncorrect = $latestIncorrect WHERE title = '$title';");
}
