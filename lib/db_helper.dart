import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DataBaseHelper {
  static Database? _db;

  static Future<Database> _createDB() async {
    final path = (await getApplicationSupportDirectory()).path;
    return databaseFactoryFfi.openDatabase(p.join(path, "study.db"),
        options: OpenDatabaseOptions(
            onCreate: (db, version) async {
              await db.execute("CREATE TABLE Subjects(title text)");
              await db.execute(
                  "CREATE TABLE Sections(subject text, title text, tableID integer primary key autoincrement, latestCorrect int, latestIncorrect int, latestStudyMode text)");
            },
            version: 3));
  }

  /// DataBaseから教科名を取得する
  static Future<List<String>> getSubjectTitles() async {
    _db ??= await _createDB();
    final titlesMap = await _db!.query('Subjects', columns: ["title"]);

    List<String> titles = [];
    for (var map in titlesMap) {
      titles.add(map["title"].toString());
    }
    return titles;
  }

  /// 初期の教科を作成する
  static void createSubject(String title) async {
    _db ??= await _createDB();
    _db!.insert("Subjects", Subject(title: title).toMap());
  }

  /// DataBaseから教科を削除する
  static Future<int> removeSubject(String title) async {
    _db ??= await _createDB();
    return _db!.delete("Subjects", where: "title='$title'");
  }

  /// セクションを作成
  static Future<int> createSection(String subjectName, String title) async {
    _db ??= await _createDB();
    int tableID = DateTime.now().millisecondsSinceEpoch;

    // 問題集のTableを作成
    await _db!.execute(
        "CREATE TABLE Section_$tableID(id integer primary key autoincrement, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int)");

    // セクション一覧にIDなどを記録
    return _db!.insert(
        "Sections",
        Section(
                subject: subjectName,
                title: title,
                tableID: tableID,
                latestCorrect: 0,
                latestIncorrect: 0,
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
  static Future<Section> getSectionData(int tableID) async {
    final sectionsMaps =
        await _db!.query('Sections', where: "tableID='$tableID'");

    return Section.tableMapToModel(sectionsMaps.first);
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
  static Future<List<MiQuestion>> getMiQuestions(int sectionID) async {
    _db ??= await _createDB();
    final miQuestionsMaps = await _db!.query('Section_$sectionID');

    final miList = <MiQuestion>[];
    for (var map in miQuestionsMaps) {
      miList.add(MiQuestion.tableMapToModel(map));
    }
    return miList;
  }

  /// Sectionの概要データの更新
  static Future<int> updateSectionRecord(int sectionID, int latestCorrect,
      int latestIncorrect, String latestStudyMode) {
    return _db!.rawUpdate(
        "UPDATE Sections SET latestCorrect = $latestCorrect, latestIncorrect = $latestIncorrect, latestStudyMode = '$latestStudyMode' WHERE tableID = $sectionID;");
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
}

/// 教科一覧のモデル
class Subject {
  /// 教科名
  final String title;

  Subject({required this.title});

  Map<String, Object?> toMap() {
    {
      return {
        'title': title,
      };
    }
  }
}

/// セクション一覧のモデル
class Section {
  /// 所属教科
  final String subject;

  /// セクション名
  final String title;

  /// 前回の学習の正解の問題数
  final int latestCorrect;

  /// 前回の学習の不正解の問題数
  final int latestIncorrect;

  /// 前回の結果のモード
  final String latestStudyMode;

  /// テーブルのID
  final int tableID;

  Section(
      {required this.subject,
      required this.title,
      required this.latestCorrect,
      required this.latestIncorrect,
      required this.latestStudyMode,
      required this.tableID});

  Map<String, Object?> toMap() {
    {
      return {
        'subject': subject,
        'title': title,
        'tableID': tableID,
        "latestCorrect": latestCorrect,
        "latestIncorrect": latestIncorrect,
        "latestStudyMode": latestStudyMode
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static Section tableMapToModel(Map<String, Object?> map) {
    return Section(
        subject: map["subject"].toString(),
        title: map["title"].toString(),
        tableID: map["tableID"] as int,
        latestCorrect: map["latestCorrect"] as int,
        latestIncorrect: map["latestIncorrect"] as int,
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

  MiQuestion(
      {required this.id,
      required this.question,
      required this.choices,
      required this.answer,
      required this.isInput});

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
        isInput: (map["input"] as int) == 1 ? true : false);
  }
}
