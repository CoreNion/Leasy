import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mimosa/pages/subjects.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../utility.dart';
import '../helper/subject.dart';
import 'setup.dart';
import 'create.dart';
import 'setting.dart';
import 'subject/overview.dart';

import '../helper/dummy.dart' if (dart.library.html) 'dart:html' as html;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  GlobalKey subjectListKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 起動時にダイナミックカラーが読み込まれない問題の対策
      MyApp.rootSetState(context, () {});

      // 初回セットアップ(初期画面)を表示
      if (!(MyApp.prefs.getBool("setup") ?? false)) {
        // 大画面デバイスではDialogで表示
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
                  child: const SizedBox(height: 650, child: SetupPage())));
        }
        await MyApp.prefs.setBool("setup", true);

        // Web版の場合はデータベースなどを完全に読み込むためにリロード
        if (kIsWeb) html.window.location.reload();
        setState(() {});
      } else if (MyApp.updated) {
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          padding: const EdgeInsets.all(10),
          content: Text(
              "アプリはv${MyApp.packageInfo.version}に更新されました。\nアップデートの内容は、サイトをご覧ください。"),
          leading: const Icon(Icons.upgrade),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                launchUrl(Uri.https("github.com",
                    "/CoreNion/Leasy/releases/tag/v${MyApp.packageInfo.version}"));
              },
              child: const Text('サイトを開く'),
            ),
          ],
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final largeSC = checkLargeSC(context);

    final List<Widget> tabPages = <Widget>[
      SubjectListPage(key: subjectListKey),
      const CreateSubjectPage(),
      const SettingPage(),
    ];
    const List<String> pageTitles = <String>[
      "Leasy",
      "教科を新規作成する",
      "設定",
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(pageTitles[pageIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (selectedIndex) async {
          HapticFeedback.mediumImpact();

          // 作成ボタンが押されたらダイアログ/モーダルを表示
          if (selectedIndex == 1) {
            late String? title;
            if (largeSC) {
              title = await showDialog(
                  context: context,
                  builder: (builder) {
                    return Dialog(
                        child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500.0),
                      child: tabPages[1],
                    ));
                  });
            } else {
              title = await showModalBottomSheet<String?>(
                  backgroundColor: Colors.transparent,
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return tabPages[1];
                  });
            }

            if (title != null) {
              // 作成処理
              final subInfo = await createSubject(title);

              // 教科一覧を更新
              subjectListKey.currentState!.setState(() {});

              // 教科ページへ移動
              if (context.mounted) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) =>
                            SubjectOverview(subInfo: subInfo))));
              }
            }
          } else {
            setState(() => pageIndex = selectedIndex);
          }
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add),
            selectedIcon: Icon(Icons.add),
            label: '教科を作成',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        selectedIndex: pageIndex,
      ),
      body: tabPages[pageIndex],
    );
  }
}
