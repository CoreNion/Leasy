import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class DataBaseHelper {
  static Database? _db;

  static Future<Database> _createDB() async {
    return databaseFactoryFfi.openDatabase(
        p.join(await getDatabasesPath(), "subjects.db"),
        options: OpenDatabaseOptions(
            onCreate: (db, version) =>
                db.execute("CREATE TABLE Subjects(title text)"),
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
}

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
