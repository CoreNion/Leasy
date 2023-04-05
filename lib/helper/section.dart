import 'common.dart';
import '../class/section.dart';

/// Sections DataBaseにセクションを作成
Future<int> createSection(int subjectID, String title) async {
  int tableID = DateTime.now().millisecondsSinceEpoch;

  // 問題集のTableを作成
  await studyDB.execute(
      "CREATE TABLE Section_$tableID(id integer primary key autoincrement, question text, choice1 text, choice2 text, choice3 text, choice4 text, answer int, input int, latestCorrect int)");

  // セクション一覧にIDなどを記録
  return studyDB.insert(
      "Sections",
      SectionInfo(
              subjectID: subjectID,
              title: title,
              tableID: tableID,
              latestStudyMode: "no")
          .toMap());
}

/// Sections DataBaseから指定された教科に所属しているセクションIDを取得する
Future<List<int>> getSectionIDs(int subjectID) async {
  final idsMap = await studyDB.query('Sections',
      columns: ["tableID"], where: "subjectID='$subjectID'");

  List<int> ids = [];
  for (var map in idsMap) {
    ids.add(map.cast()["tableID"]);
  }
  return ids;
}

/// セクションIDからタイトルを取得
Future<String> sectionIDtoTitle(int id) async {
  final titlesMap = await studyDB.query('Sections',
      columns: ["title"], where: "tableID='$id'");

  return titlesMap.first["title"].toString();
}

/// TableIDからSection情報を取得
Future<SectionInfo> getSectionData(int tableID) async {
  final sectionsMaps =
      await studyDB.query('Sections', where: "tableID='$tableID'");

  return SectionInfo.tableMapToModel(sectionsMaps.first);
}

/// DataBaseから一致したセクションを削除する
Future<int> removeSection(int subjectID, int id) async {
  // セクションの問題集を削除
  await studyDB.execute("DROP TABLE Section_$id");
  // セクション一覧から削除
  return studyDB.delete("Sections",
      where: "subjectID='$subjectID' AND tableID='$id'");
}

// セクション名を変更
Future<int> renameSectionName(int tableID, String name) {
  return studyDB.rawUpdate(
      "UPDATE Sections SET title = '$name' WHERE tableID = $tableID;");
}
