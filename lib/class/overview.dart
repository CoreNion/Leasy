/// 概要の種類
enum OverviewType {
  subject,
  section;

  @override
  String toString() {
    switch (this) {
      case OverviewType.subject:
        return "教科";
      case OverviewType.section:
        return "セクション";
    }
  }
}
