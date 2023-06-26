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

/// サインイン時の例外
class SignInException implements Exception {
  String cause;
  SignInException(this.cause);
}

/// 初期サインイン時の例外
class InitSignInException implements SignInException {
  @override
  String cause;

  InitSignInException(this.cause);
}

/// Auth関連の例外
class AuthException implements SignInException {
  @override
  String cause;

  AuthException(this.cause);
}

/// クラウドサービス全般の例外
class CloudServiceException implements Exception {
  String cause;
  CloudServiceException(this.cause);
}

/// ファイルAPIの例外
class FileApiException implements CloudServiceException {
  @override
  String cause;

  FileApiException(this.cause);
}
