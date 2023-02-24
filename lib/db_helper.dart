import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DataBaseHelper {
  static Database? _db;

  static Future<Database> _createDB() async {
    if (kIsWeb) {
      return databaseFactoryFfiWeb.openDatabase("study.db",
          options: OpenDatabaseOptions(
              onCreate: (db, version) async {
                await db.execute(
                    "CREATE TABLE Subjects(title text, latestCorrect int, latestIncorrect int)");
                await db.execute(
                    "CREATE TABLE Sections(subject text, title text, tableID integer primary key autoincrement, latestStudyMode text)");
              },
              version: 3));
    } else {
      final path = (await getApplicationSupportDirectory()).path;
      return databaseFactoryFfi.openDatabase(p.join(path, "study.db"),
          options: OpenDatabaseOptions(
              onCreate: (db, version) async {
                await db.execute(
                    "CREATE TABLE Subjects(title text, latestCorrect int, latestIncorrect int)");
                await db.execute(
                    "CREATE TABLE Sections(subject text, title text, tableID integer primary key autoincrement, latestStudyMode text)");
              },
              version: 3));
    }
  }

  /// DataBaseから教科名を取得する
  static Future<List<SubjectInfo>> getSubjectInfos() async {
    _db ??= await _createDB();
    final subInfoMaps = await _db!.query('Subjects');

    List<SubjectInfo> subInfos = [];
    for (var subInfo in subInfoMaps) {
      subInfos.add(SubjectInfo.tableMapToModel(subInfo));
    }
    return subInfos;
  }

  /// 初期の教科を作成する
  static void createSubject(String title) async {
    _db ??= await _createDB();
    _db!.insert(
        "Subjects",
        SubjectInfo(title: title, latestCorrect: 0, latestIncorrect: 0)
            .toMap());
  }

  /// DataBaseから教科を削除する
  static Future<int> removeSubject(String title) async {
    _db ??= await _createDB();
    return _db!.delete("Subjects", where: "title='$title'");
  }

  static Future<int> updateSubjectRecord(
      String title, int latestCorrect, int latestIncorrect) {
    return _db!.rawUpdate(
        "UPDATE Subjects SET latestCorrect = $latestCorrect, latestIncorrect = $latestIncorrect WHERE title = '$title';");
  }

  /// セクションを作成
  static Future<int> createSection(String subjectName, String title) async {
    _db ??= await _createDB();
    int tableID = DateTime.now().millisecondsSinceEpoch;

    // 問題集のTableを作成
    await _db!.execute(
        "CREATE TABLE Section_$tableID(id integer primary key autoincrement, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int, latestCorrect int)");

    // セクション一覧にIDなどを記録
    return _db!.insert(
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
    _db ??= await _createDB();
    final idsMap = await _db!.query('Sections',
        columns: ["tableID"], where: "subject='$subjectName'");

    List<int> ids = [];
    for (var map in idsMap) {
      ids.add(map.cast()["tableID"]);
    }
    return ids;
  }

  /// セクションIDからタイトルを取得
  static Future<String> sectionIDtoTitle(int id) async {
    _db ??= await _createDB();
    final titlesMap = await _db!
        .query('Sections', columns: ["title"], where: "tableID='$id'");

    return titlesMap.first["title"].toString();
  }

  /// TableIDからSectionを取得
  static Future<SectionInfo> getSectionData(int tableID) async {
    final sectionsMaps =
        await _db!.query('Sections', where: "tableID='$tableID'");

    return SectionInfo.tableMapToModel(sectionsMaps.first);
  }

  /// DataBaseから一致したセクションを削除する
  static Future<int> removeSection(String subjectName, int id) async {
    _db ??= await _createDB();
    // セクションの問題集を削除
    _db!.execute("DROP TABLE Section_$id");
    // セクション一覧から削除
    return _db!
        .delete("Sections", where: "subject='$subjectName' AND tableID='$id'");
  }

  // セクションの問題を作成する
  static Future<void> createQuestion(int sectionID, MiQuestion question) async {
    _db ??= await _createDB();
    _db!.insert("Section_$sectionID", question.toTableMap());
  }

  /// セクションの問題を削除
  static Future<void> removeQuestion(int sectionID, int questionID) async {
    _db ??= await _createDB();
    _db!.delete("Section_$sectionID", where: "id='$questionID'");
  }

  /// セクションのMiQuestion一覧を取得
  static Future<List<MiQuestion>> getMiQuestions(List<int> sectionIDs) async {
    final miList = <MiQuestion>[];

    for (var secID in sectionIDs) {
      final miQuestionsMaps = await _db!.query('Section_$secID');
      for (var map in miQuestionsMaps) {
        miList.add(MiQuestion.tableMapToModel(map));
      }
    }

    return miList;
  }

  /// Sectionの概要データの更新
  static Future<int> updateSectionRecord(
      int sectionID, String latestStudyMode) {
    return _db!.rawUpdate(
        "UPDATE Sections SET latestStudyMode = '$latestStudyMode' WHERE tableID = $sectionID;");
  }

  /// IDからMiQuestionを返す
  static Future<MiQuestion> getMiQuestion(int sectionID, int id) async {
    _db ??= await _createDB();
    final miQuestionsMaps =
        await _db!.query('Section_$sectionID', where: "id='$id'");

    return MiQuestion.tableMapToModel(miQuestionsMaps.first);
  }

  /// MiQuestionの更新
  static Future<int> updateMiQuestion(
      int sectionID, int id, MiQuestion question) async {
    return _db!
        .update("Section_$sectionID", question.toTableMap(), where: "id='$id'");
  }

  /// Questionの学習記録の更新
  static Future<int> updateQuestionRecord(
      int sectionID, bool correct, int questionID) {
    return _db!.rawUpdate(
        "UPDATE Section_$sectionID SET latestCorrect = '${correct ? 1 : 0}' WHERE id = $questionID;");
  }

  /// Questionの学習記録を取得
  static Future<List<bool?>> getQuestionRecords(
      int sectionID, bool correct, int questionID) async {
    final recordsMap =
        await _db!.query('Section_$sectionID', columns: ["latestCorrect"]);

    List<bool?> records = [];
    for (var map in recordsMap) {
      records.add(map.cast()["latestCorrect"]);
    }
    return records;
  }
}

/// 教科一覧のモデル
class SubjectInfo {
  /// 教科名
  final String title;

  /// 前回の学習の正解の問題数
  final int latestCorrect;

  /// 前回の学習の不正解の問題数
  final int latestIncorrect;

  SubjectInfo(
      {required this.title,
      required this.latestCorrect,
      required this.latestIncorrect});

  Map<String, Object?> toMap() {
    {
      return {
        'title': title,
        'latestCorrect': latestCorrect,
        'latestIncorrect': latestIncorrect
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static SubjectInfo tableMapToModel(Map<String, Object?> map) {
    return SubjectInfo(
        title: map["title"].toString(),
        latestCorrect: map["latestCorrect"] as int,
        latestIncorrect: map["latestIncorrect"] as int);
  }
}

/// セクション一覧のモデル
class SectionInfo {
  /// 所属教科
  final String subject;

  /// セクション名
  final String title;

  /// 前回の結果のモード
  final String latestStudyMode;

  /// テーブルのID
  final int tableID;

  SectionInfo(
      {required this.subject,
      required this.title,
      required this.latestStudyMode,
      required this.tableID});

  Map<String, Object?> toMap() {
    {
      return {
        'subject': subject,
        'title': title,
        'tableID': tableID,
        "latestStudyMode": latestStudyMode
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static SectionInfo tableMapToModel(Map<String, Object?> map) {
    return SectionInfo(
        subject: map["subject"].toString(),
        title: map["title"].toString(),
        tableID: map["tableID"] as int,
        latestStudyMode: map["latestStudyMode"].toString());
  }
}

/// セクションの問題集(MiQuestion)のモデル
class MiQuestion {
  final int id;

  final String question;

  final List<String> choices;

  final int answer;

  final bool isInput;

  final bool? latestCorrect;

  MiQuestion(
      {required this.id,
      required this.question,
      required this.choices,
      required this.answer,
      required this.isInput,
      this.latestCorrect});

  // DataBaseの形式のMapに変換する関数
  Map<String, Object?> toTableMap() {
    {
      return {
        'id': id,
        'question': question,
        'choice1': choices[0],
        'choice2': choices[1],
        'choice3': choices[2],
        'choice4': choices[3],
        'answer': answer,
        'input': isInput ? 1 : 0,
        'latestCorrect': latestCorrect != null ? (latestCorrect! ? 1 : 0) : null
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static MiQuestion tableMapToModel(Map<String, Object?> map) {
    return MiQuestion(
        id: map["id"] as int,
        question: map["question"].toString(),
        choices: [
          map["choice1"].toString(),
          map["choice2"].toString(),
          map["choice3"].toString(),
          map["choice4"].toString()
        ],
        answer: map["answer"] as int,
        isInput: (map["input"] as int) == 1 ? true : false,
        latestCorrect: (map["latestCorrect"] as int?) != null
            ? ((map["latestCorrect"] as int) == 1 ? true : false)
            : null);
  }
}
