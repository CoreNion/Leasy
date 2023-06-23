/// 利用しているクラウドの種類
enum CloudType {
  none,
  google,
  icloud;

  @override
  String toString() {
    switch (this) {
      case CloudType.none:
        return "未接続 (ログアウト中)";
      case CloudType.google:
        return "Google Driveと接続中";
      case CloudType.icloud:
        return "iCloudと接続中";
    }
  }
}

/// クラウドのアカウント情報のモデル
class CloudAccountInfo {
  /// クラウドの種類
  final CloudType type;

  /// クラウドのアカウントのメールアドレス
  final String? email;

  CloudAccountInfo({required this.type, required this.email});
}
