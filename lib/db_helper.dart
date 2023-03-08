import 'class/question.dart';
import 'class/section.dart';
import 'class/subject.dart';
import 'helper/common.dart';

class DataBaseHelper {
  /// DataBaseから教科名を取得する
  static Future<List<SubjectInfo>> getSubjectInfos() async {
    final subInfoMaps = await studyDB.query('Subjects');

    List<SubjectInfo> subInfos = [];
    for (var subInfo in subInfoMaps) {
      subInfos.add(SubjectInfo.tableMapToModel(subInfo));
    }
    return subInfos;
  }

  /// 初期の教科を作成する
  static void createSubject(String title) async {
    studyDB.insert(
        "Subjects",
        SubjectInfo(title: title, latestCorrect: 0, latestIncorrect: 0)
            .toMap());
  }

  /// DataBaseから教科を削除する
  static Future<int> removeSubject(String title) async {
    return studyDB.delete("Subjects", where: "title='$title'");
  }

  static Future<int> updateSubjectRecord(
      String title, int latestCorrect, int latestIncorrect) {
    return studyDB.rawUpdate(
        "UPDATE Subjects SET latestCorrect = $latestCorrect, latestIncorrect = $latestIncorrect WHERE title = '$title';");
  }

  /// セクションを作成
  static Future<int> createSection(String subjectName, String title) async {
    int tableID = DateTime.now().millisecondsSinceEpoch;

    // 問題集のTableを作成
    await studyDB.execute(
        "CREATE TABLE Section_$tableID(id integer primary key autoincrement, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int, latestCorrect int)");

    // セクション一覧にIDなどを記録
    return studyDB.insert(
        "Sections",
        SectionInfo(
                subject: subjectName,
                title: title,
                tableID: tableID,
                latestStudyMode: "no")
            .toMap());
  }

  /// Sections DataBaseから教科に所属しているセクションIDを取得する
  static Future<List<int>> getSectionIDs(String subjectName) async {
    final idsMap = await studyDB.query('Sections',
        columns: ["tableID"], where: "subject='$subjectName'");

    List<int> ids = [];
    for (var map in idsMap) {
      ids.add(map.cast()["tableID"]);
    }
    return ids;
  }

  /// セクションIDからタイトルを取得
  static Future<String> sectionIDtoTitle(int id) async {
    final titlesMap = await studyDB.query('Sections',
        columns: ["title"], where: "tableID='$id'");

    return titlesMap.first["title"].toString();
  }

  /// TableIDからSectionを取得
  static Future<SectionInfo> getSectionData(int tableID) async {
    final sectionsMaps =
        await studyDB.query('Sections', where: "tableID='$tableID'");

    return SectionInfo.tableMapToModel(sectionsMaps.first);
  }

  /// DataBaseから一致したセクションを削除する
  static Future<int> removeSection(String subjectName, int id) async {
    // セクションの問題集を削除
    studyDB.execute("DROP TABLE Section_$id");
    // セクション一覧から削除
    return studyDB.delete("Sections",
        where: "subject='$subjectName' AND tableID='$id'");
  }

  // セクションの問題を作成する
  static Future<void> createQuestion(int sectionID, MiQuestion question) async {
    studyDB.insert("Section_$sectionID", question.toTableMap());
  }

  /// セクションの問題を削除
  static Future<void> removeQuestion(int sectionID, int questionID) async {
    studyDB.delete("Section_$sectionID", where: "id='$questionID'");
  }

  /// セクションのMiQuestion一覧を取得
  static Future<List<MiQuestion>> getMiQuestions(List<int> sectionIDs) async {
    final miList = <MiQuestion>[];

    for (var secID in sectionIDs) {
      final miQuestionsMaps = await studyDB.query('Section_$secID');
      for (var map in miQuestionsMaps) {
        miList.add(MiQuestion.tableMapToModel(map));
      }
    }

    return miList;
  }

  /// Sectionの概要データの更新
  static Future<int> updateSectionRecord(
      int sectionID, String latestStudyMode) {
    return studyDB.rawUpdate(
        "UPDATE Sections SET latestStudyMode = '$latestStudyMode' WHERE tableID = $sectionID;");
  }

  /// IDからMiQuestionを返す
  static Future<MiQuestion> getMiQuestion(int sectionID, int id) async {
    final miQuestionsMaps =
        await studyDB.query('Section_$sectionID', where: "id='$id'");

    return MiQuestion.tableMapToModel(miQuestionsMaps.first);
  }

  /// MiQuestionの更新
  static Future<int> updateMiQuestion(
      int sectionID, int id, MiQuestion question) async {
    return studyDB.update("Section_$sectionID", question.toTableMap(),
        where: "id='$id'");
  }

  /// Questionの学習記録の更新
  static Future<int> updateQuestionRecord(
      int sectionID, bool correct, int questionID) {
    return studyDB.rawUpdate(
        "UPDATE Section_$sectionID SET latestCorrect = '${correct ? 1 : 0}' WHERE id = $questionID;");
  }

  /// Questionの学習記録を取得
  static Future<List<bool?>> getQuestionRecords(
      int sectionID, bool correct, int questionID) async {
    final recordsMap =
        await studyDB.query('Section_$sectionID', columns: ["latestCorrect"]);

    List<bool?> records = [];
    for (var map in recordsMap) {
      records.add(map.cast()["latestCorrect"]);
    }
    return records;
  }
}
