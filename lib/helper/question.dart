import 'common.dart';
import '../class/question.dart';

/// データベースのセクションに問題を作成する
Future<int> createQuestion(MiQuestion question) async {
  return studyDB.insert("Questions", question.toTableMap());
}

/// データベース上の指定された問題を削除
Future<int> removeQuestion(int questionID) async {
  return studyDB.delete("Questions", where: "id = ?", whereArgs: [questionID]);
}

/// データベース上の指定されたセクションのMiQuestion一覧を取得
Future<List<MiQuestion>> getMiQuestions(List<int> sectionIDs) async {
  final miList = <MiQuestion>[];

  for (var secID in sectionIDs) {
    final miQuestionsMaps = await studyDB
        .query('Questions', where: "sectionID = ?", whereArgs: [secID]);
    for (var map in miQuestionsMaps) {
      miList.add(MiQuestion.tableMapToModel(map));
    }
  }

  return miList;
}

/// IDからMiQuestionを返す
Future<MiQuestion> getMiQuestion(int id) async {
  final miQuestionsMaps =
      await studyDB.query('Questions', where: "id = ?", whereArgs: [id]);

  return MiQuestion.tableMapToModel(miQuestionsMaps.first);
}

/// 指定されたIDのMiQuestionの更新
Future<int> updateMiQuestion(int id, MiQuestion question) async {
  return studyDB.update("Questions", question.toTableMap(),
      where: "id = ?", whereArgs: [id]);
}

/// 指定されたMiQuestionの学習記録の更新
Future<int> updateQuestionRecord(int questionID, bool correct) {
  final updateValues = {"latestCorrect": correct ? 1 : 0};
  return studyDB.update("Questions", updateValues,
      where: "id = ?", whereArgs: [questionID]);
}

/// 指定されたセクションの学習記録を取得
Future<List<bool?>> getQuestionRecords(int sectionID) async {
  final recordsMap = await studyDB.query('Questions',
      columns: ["latestCorrect"],
      where: "sectionID = ?",
      whereArgs: [sectionID]);

  List<bool?> records = [];
  for (var map in recordsMap) {
    records.add(map.cast()["latestCorrect"]);
  }
  return records;
}
