import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../widgets/settings/general.dart';
import '../utility.dart';
import 'setup.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(17),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: <Widget>[
                const ScreenSettings(),
                const SizedBox(height: 25),
                const DataSettings(),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: ListTile(
                      title: const Text("チュートリアルを開く"),
                      subtitle: const Text("初回起動時に表示されたチュートリアルを開きます。"),
                      tileColor: colorScheme.background,
                      trailing: Icon(Icons.support, color: colorScheme.primary),
                      onTap: () async {
                        if (checkLargeSC(context)) {
                          await showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (builder) {
                                return WillPopScope(
                                    onWillPop: () async => false,
                                    child: const Dialog(
                                      child: SizedBox(
                                        height: 600,
                                        width: 700,
                                        child: SetupPage(),
                                      ),
                                    ));
                              });
                        } else {
                          await showModalBottomSheet(
                              isDismissible: false,
                              context: context,
                              isScrollControlled: true,
                              enableDrag: false,
                              backgroundColor: Colors.transparent,
                              useSafeArea: true,
                              builder: (builder) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: const SizedBox(
                                      height: 650, child: SetupPage())));
                        }
                      }),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: ListTile(
                    title: const Text("アプリ情報"),
                    tileColor: colorScheme.background,
                    subtitle: Text("v${MyApp.packageInfo.version}"),
                    trailing: Icon(Icons.info, color: colorScheme.primary),
                    onTap: () => showAboutDialog(
                        context: context,
                        applicationName: "Leasy",
                        applicationVersion: "v${MyApp.packageInfo.version}",
                        applicationLegalese: "(c) 2023 CoreNion\n",
                        children: [
                          TextButton(
                              onPressed: () {
                                launchUrl(
                                    Uri.https("corenion.github.io", "/leasy"));
                              },
                              child: const Text("ホームページ")),
                        ],
                        applicationIcon: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            child: SvgPicture.asset(
                              'assets/icon.svg',
                              width: 80,
                              height: 80,
                            ))),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
