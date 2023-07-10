import 'common.dart';
import '../class/question.dart';
import 'cloud/common.dart';

/// データベースのセクションに問題を作成する
Future<void> createQuestion(MiQuestion question) async {
  await studyDB.insert("Questions", question.toTableMap());
  await saveToCloud();
}

/// データベース上の指定された問題を削除
Future<void> removeQuestion(int questionID) async {
  await studyDB.delete("Questions", where: "id = ?", whereArgs: [questionID]);
  await saveToCloud();
}

/// 指定された単一セクションのMiQuestion概要(IDと問題/正誤)を取得
Future<List<MiQuestionSummary>> getMiQuestionSummaries(int sectionID) async {
  final results = await studyDB.query('Questions',
      columns: [
        "id",
        "question",
        "latestCorrect",
        "totalCorrect",
        "totalInCorrect"
      ],
      where: "sectionID = ?",
      whereArgs: [sectionID]);

  return results.map((e) => MiQuestionSummary.tableMapToModel(e)).toList();
}

/// データベース上の指定されたセクションのMiQuestionのID一覧を取得
Future<List<int>> getMiQuestionsID(List<int> sectionIDs) async {
  final results = await studyDB.query('Questions',
      columns: ["id"],
      where: "sectionID IN (${List.filled(sectionIDs.length, '?').join(',')})",
      whereArgs: sectionIDs);

  return results.map((e) => e["id"] as int).toList();
}

/// IDからMiQuestionを返す
Future<MiQuestion> getMiQuestion(int id) async {
  final miQuestionsMaps =
      await studyDB.query('Questions', where: "id = ?", whereArgs: [id]);

  return MiQuestion.tableMapToModel(miQuestionsMaps.first);
}

/// 指定されたIDのMiQuestionの更新
Future<void> updateMiQuestion(int id, MiQuestion question) async {
  await studyDB.update("Questions", question.toTableMap(),
      where: "id = ?", whereArgs: [id]);
  await saveToCloud();
}

/// 指定されたMiQuestionの学習記録の更新
Future<void> updateQuestionRecord(int questionID, bool correct) async {
  // 最新の正誤の更新
  final updateLatestCorrectVal = {"latestCorrect": correct ? 1 : 0};
  await studyDB.update("Questions", updateLatestCorrectVal,
      where: "id = ?", whereArgs: [questionID]);

  /* 合計正解数/不正解数の更新 */
  // 今までの合計正解数/不正解数を取得
  late int totalCorrests;
  final totalMap = await studyDB.query('Questions',
      columns: [correct ? "totalCorrect" : "totalInCorrect"],
      where: "id = ?",
      whereArgs: [questionID]);
  for (var map in totalMap) {
    totalCorrests = map[correct ? "totalCorrect" : "totalInCorrect"] as int;
  }

  // 合計正解数/不正解数を更新
  await studyDB.update(
      "Questions",
      {
        correct ? "totalCorrect" : "totalInCorrect": totalCorrests + 1,
      },
      where: "id = ?",
      whereArgs: [questionID]);

  await saveToCloud();
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
