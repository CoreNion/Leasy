import 'common.dart';
import '../class/question.dart';

/// データベースのセクションに問題を作成する
Future<int> createQuestion(MiQuestion question) async {
  return studyDB.insert("Questions", question.toTableMap());
}

/// データベース上の指定された問題を削除
Future<int> removeQuestion(int questionID) async {
  return studyDB.delete("Questions", where: "id='$questionID'");
}

/// データベース上の指定されたセクションのMiQuestion一覧を取得
Future<List<MiQuestion>> getMiQuestions(List<int> sectionIDs) async {
  final miList = <MiQuestion>[];

  for (var secID in sectionIDs) {
    final miQuestionsMaps =
        await studyDB.query('Questions', where: "sectionID='$secID'");
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
Future<MiQuestion> getMiQuestion(int id) async {
  final miQuestionsMaps = await studyDB.query('Questions', where: "id='$id'");

  return MiQuestion.tableMapToModel(miQuestionsMaps.first);
}

/// 指定されたIDのMiQuestionの更新
Future<int> updateMiQuestion(int id, MiQuestion question) async {
  return studyDB.update("Questions", question.toTableMap(), where: "id='$id'");
}

/// 指定されたMiQuestionの学習記録の更新
Future<int> updateQuestionRecord(int questionID, bool correct) {
  return studyDB.rawUpdate(
      "UPDATE Questions SET latestCorrect = '${correct ? 1 : 0}' WHERE id = $questionID;");
}

/// 指定されたセクションの学習記録を取得
Future<List<bool?>> getQuestionRecords(int sectionID) async {
  final recordsMap = await studyDB.query('Questions',
      columns: ["latestCorrect"], where: "sectionID='$sectionID'");

  List<bool?> records = [];
  for (var map in recordsMap) {
    records.add(map.cast()["latestCorrect"]);
  }
  return records;
}
