import 'common.dart';
import '../class/question.dart';

/// データベースのセクションに問題を作成する
Future<int> createQuestion(int sectionID, MiQuestion question) async {
  return studyDB.insert("Section_$sectionID", question.toTableMap());
}

/// データベース上の指定されたセクションの問題を削除
Future<int> removeQuestion(int sectionID, int questionID) async {
  return studyDB.delete("Section_$sectionID", where: "id='$questionID'");
}

/// データベース上の指定されたセクションのMiQuestion一覧を取得
Future<List<MiQuestion>> getMiQuestions(List<int> sectionIDs) async {
  final miList = <MiQuestion>[];

  for (var secID in sectionIDs) {
    final miQuestionsMaps = await studyDB.query('Section_$secID');
    for (var map in miQuestionsMaps) {
      miList.add(MiQuestion.tableMapToModel(map));
    }
  }

  return miList;
}

/// 指定されたセクションの概要データの更新
Future<int> updateSectionRecord(int sectionID, String latestStudyMode) {
  return studyDB.rawUpdate(
      "UPDATE Sections SET latestStudyMode = '$latestStudyMode' WHERE tableID = $sectionID;");
}

/// IDからMiQuestionを返す
Future<MiQuestion> getMiQuestion(int sectionID, int id) async {
  final miQuestionsMaps =
      await studyDB.query('Section_$sectionID', where: "id='$id'");

  return MiQuestion.tableMapToModel(miQuestionsMaps.first);
}

/// 指定されたIDのMiQuestionの更新
Future<int> updateMiQuestion(int sectionID, int id, MiQuestion question) async {
  return studyDB.update("Section_$sectionID", question.toTableMap(),
      where: "id='$id'");
}

/// 指定されたMiQuestionの学習記録の更新
Future<int> updateQuestionRecord(int sectionID, bool correct, int questionID) {
  return studyDB.rawUpdate(
      "UPDATE Section_$sectionID SET latestCorrect = '${correct ? 1 : 0}' WHERE id = $questionID;");
}

/// 指定されたMiQuestionの学習記録を取得
Future<List<bool?>> getQuestionRecords(
    int sectionID, bool correct, int questionID) async {
  final recordsMap =
      await studyDB.query('Section_$sectionID', columns: ["latestCorrect"]);

  List<bool?> records = [];
  for (var map in recordsMap) {
    records.add(map.cast()["latestCorrect"]);
  }
  return records;
}
