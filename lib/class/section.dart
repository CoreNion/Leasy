/// セクション情報のモデル
class SectionInfo {
  /// 所属教科のID
  final int subjectID;

  /// セクション名
  final String title;

  /// 前回の結果のモード
  final String latestStudyMode;

  /// テーブルのID
  final int tableID;

  /// 完了率 (データベース非対応)
  double? completionRate;

  SectionInfo(
      {required this.subjectID,
      required this.title,
      required this.latestStudyMode,
      required this.tableID,
      completionRate});

  SectionInfo copyWith(
      {int? subjectID,
      String? title,
      String? latestStudyMode,
      int? tableID,
      double? completionRate}) {
    return SectionInfo(
        subjectID: subjectID ?? this.subjectID,
        title: title ?? this.title,
        latestStudyMode: latestStudyMode ?? this.latestStudyMode,
        tableID: tableID ?? this.tableID,
        completionRate: completionRate ?? this.completionRate);
  }

  Map<String, Object?> toMap() {
    {
      return {
        'subjectID': subjectID,
        'title': title,
        'tableID': tableID,
        "latestStudyMode": latestStudyMode
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static SectionInfo tableMapToModel(Map<String, Object?> map) {
    return SectionInfo(
        subjectID: map["subjectID"] as int,
        title: map["title"].toString(),
        tableID: map["tableID"] as int,
        latestStudyMode: map["latestStudyMode"].toString());
  }
}
