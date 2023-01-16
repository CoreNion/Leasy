import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class DataBaseHelper {
  static Database? _db;

  static Future<Database> _createDB() async {
    return databaseFactoryFfi.openDatabase(
        p.join(await getDatabasesPath(), "study.db"),
        options: OpenDatabaseOptions(
            onCreate: (db, version) async {
              await db.execute("CREATE TABLE Subjects(title text)");
              await db.execute(
                  "CREATE TABLE Sections(subject text, title text, tableID integer primary key autoincrement)");
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
    _db!.insert("Subjects", SubjectsModel(title: title).toMap());
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
        "CREATE TABLE Section_$tableID(question text, choice1 text, choice2 text, choice3 text, choice4 text)");

    // セクション一覧にIDなどを記録
    return _db!.insert(
        "Sections",
        SectionsModel(subject: subjectName, title: title, tableID: tableID)
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
  static void createQuestion(int sectionID, QuestionModel question) async {
    _db ??= await _createDB();
    _db!.insert("Section_$sectionID", question.toMap());
  }

  /// セクションの問題を削除
  static Future<void> removeQuestion(int sectionID, String questionStr) async {
    _db ??= await _createDB();
    _db!.delete("Section_$sectionID", where: "question='$questionStr'");
  }

  /// セクションのMiQuestion一覧を取得
  static Future<List<QuestionModel>> getMiQuestions(int sectionID) async {
    _db ??= await _createDB();
    final miQuestionsMaps = (await _db!.query('Section_$sectionID'));

    final miList = <QuestionModel>[];
    for (var map in miQuestionsMaps) {
      miList.add(QuestionModel.toModel(map));
    }
    return miList;
  }
}

/// 教科一覧のモデル
class SubjectsModel {
  /// 教科名
  final String title;

  SubjectsModel({required this.title});

  Map<String, Object?> toMap() {
    {
      return {
        'title': title,
      };
    }
  }
}

/// セクション一覧のモデル
class SectionsModel {
  /// 所属教科
  final String subject;

  /// セクション名
  final String title;

  /// テーブルのID
  final int tableID;

  SectionsModel(
      {required this.title, required this.tableID, required this.subject});

  Map<String, Object?> toMap() {
    {
      return {'subject': subject, 'title': title, 'tableID': tableID};
    }
  }
}

/// セクションの問題集(MiQuestion)のモデル
class QuestionModel {
  /// 問題文
  final String question;

  final String choice1;

  final String choice2;

  final String choice3;

  final String choice4;

  QuestionModel(
      {required this.question,
      required this.choice1,
      required this.choice2,
      required this.choice3,
      required this.choice4});

  Map<String, Object?> toMap() {
    {
      return {
        'question': question,
        'choice1': choice1,
        'choice2': choice2,
        'choice3': choice3,
        'choice4': choice4,
      };
    }
  }

  static QuestionModel toModel(Map<String, Object?> map) {
    return QuestionModel(
        question: map["question"].toString(),
        choice1: map["choice1"].toString(),
        choice2: map["choice2"].toString(),
        choice3: map["choice3"].toString(),
        choice4: map["choice4"].toString());
  }
}
