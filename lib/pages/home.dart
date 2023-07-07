import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../class/cloud.dart';
import '../class/subject.dart';
import '../helper/cloud/common.dart';
import '../helper/common.dart';
import '../main.dart';
import '../utility.dart';
import '../helper/subject.dart';
import 'setup.dart';
import 'create.dart';
import 'setting.dart';
import 'subject/overview.dart';

import '../helper/dummy.dart' if (dart.library.html) 'dart:html' as html;
import 'subjects.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  GlobalKey subjectListKey = GlobalKey();

  late Future<void> _loadDB;

  @override
  void initState() {
    super.initState();
    _loadDB = loadStudyDataBase();

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

  bool _loading = true;

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
      body: FutureBuilder(
          future: _loadDB,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                bool hideButton = false;
                late String content;
                if (snapshot.error is SignInException) {
                  content = "サインイン情報が利用できませんでした。\n同期を再開するには、もう一度ログインしてください。";
                } else if (snapshot.error is AuthException) {
                  content = "認証情報が利用できませんでした。\n同期を再開するには、もう一度ログインしてください。";
                } else {
                  content = "データベースの読み込みに失敗しました。\n${snapshot.error.toString()}";
                }

                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (builder) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        title: const Text("エラー"),
                        content: Text(content),
                        actions: <Widget>[
                          TextButton(
                            onPressed: hideButton
                                ? null
                                : () async {
                                    setState(() => hideButton = true);
                                    await CloudService.signOutTemporarily();
                                    await CloudService.signIn(MyApp.cloudType);

                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _loadDB = loadStudyDataBase();
                                    setState(() {
                                      _loading = true;
                                    });
                                  },
                            child: const Text("再ログイン"),
                          ),
                          TextButton(
                            onPressed: hideButton
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            child: const Text("閉じる"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              });
              return Container();
            } else if (snapshot.connectionState == ConnectionState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _loading = false;
                });
              });
              return tabPages[pageIndex];
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
      bottomNavigationBar: _loading
          ? null
          : NavigationBar(
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
                    final id = DateTime.now().millisecondsSinceEpoch;
                    final subInfo = SubjectInfo(
                        title: title,
                        latestCorrect: 0,
                        latestIncorrect: 0,
                        id: id);
                    await createSubject(subInfo);

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
    );
  }
}
