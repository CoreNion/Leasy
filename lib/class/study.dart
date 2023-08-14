/// 学習モードの種類
enum StudyMode {
  study,
  test;

  @override
  String toString() {
    switch (this) {
      case StudyMode.study:
        return "学習";
      case StudyMode.test:
        return "テスト";
    }
  }
}

/// 学習設定
class StudySettings {
  final StudyMode studyMode;

  final List<int> questionIDs;

  StudySettings(this.studyMode, this.questionIDs);
}
