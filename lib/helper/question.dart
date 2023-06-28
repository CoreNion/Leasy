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

/// 指定された単一セクションのMiQuestion概要(IDと問題/正誤)を取得
Future<Map<int, MapEntry<String, bool?>>> getMiQuestionSummaries(
    int sectionID) async {
  final results = await studyDB.query('Questions',
      columns: ["id", "question", "latestCorrect"],
      where: "sectionID = ?",
      whereArgs: [sectionID]);

  return {
    for (var e in results)
      e["id"] as int: MapEntry(
          e["question"] as String,
          (e["latestCorrect"] as int?) != null
              ? ((e["latestCorrect"] as int) == 1 ? true : false)
              : null)
  };
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
Future<int> updateMiQuestion(int id, MiQuestion question) async {
  return studyDB.update("Questions", question.toTableMap(),
      where: "id = ?", whereArgs: [id]);
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
