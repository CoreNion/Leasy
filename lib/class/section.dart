/// セクション情報のモデル
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