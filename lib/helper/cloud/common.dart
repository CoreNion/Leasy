import '../../class/cloud.dart';
import '../../main.dart';
import 'google.dart';

/// 接続中のクラウドの情報を取得する
Future<CloudAccountInfo> getCloudInfo() async {
  final cloudType = MyApp.cloudType;
  if (cloudType == CloudType.google) {
    final info = await MiGoogleService.checkLoginStatus();
    if (info != null) {
      return CloudAccountInfo(type: CloudType.google, email: info.email);
    } else {
      return CloudAccountInfo(type: CloudType.none, email: null);
    }
  } else {
    return CloudAccountInfo(type: CloudType.none, email: null);
  }
}
