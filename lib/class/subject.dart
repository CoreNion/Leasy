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
