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

  /// Sections DataBaseから教科に所属しているセクションを取得する
  static Future<List<String>> getSectionTitles(String subjectName) async {
    _db ??= await _createDB();
    final titlesMap = await _db!
        .query('Sections', columns: ["title"], where: "subject='$subjectName'");

    List<String> titles = [];
    for (var map in titlesMap) {
      titles.add(map["title"].toString());
    }
    return titles;
  }

  /// DataBaseから一致したセクションを削除する
  static Future<int> removeSection(String subjectName, String title) async {
    _db ??= await _createDB();
    return _db!
        .delete("Sections", where: "subject='$subjectName' AND title='$title'");
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

/// セクション(問題集)のモデル
class SectionModel {
  /// 問題文
  final String question;

  final String choice1;

  final String choice2;

  final String choice3;

  final String choice4;

  SectionModel(
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
}
