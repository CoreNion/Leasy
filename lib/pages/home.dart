import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../main.dart';
import '../utility.dart';
import '../helper/subject.dart';
import '../class/subject.dart';
import 'setup.dart';
import 'create.dart';
import 'setting.dart';
import 'subject/overview.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  /// 強化のドロップダウンを表示するか
  static bool showDropDown = false;

  /// 教科リストから指定されたindexのWidgetを削除する
  static void removeSubjectWidget(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeState>()!.removeSubjectWidget(index);
  }

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  // トップに表示される教科のWidgetのリスト
  static List<Widget> subejctWidgetList = [];

  void removeSubjectWidget(int index) {
    setState(() {
      subejctWidgetList.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();

    if (!(MyApp.prefs.getBool("setup") ?? false)) {
      // 初回セットアップ(初期画面)を表示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 大画面デバイスではDialogで表示
        if (checkLargeSC(context)) {
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (builder) {
                return const WillPopScope(
                    onWillPop: null,
                    child: Dialog(
                      child: FractionallySizedBox(
                        heightFactor: 0.6,
                        widthFactor: 0.6,
                        child: SetupPage(),
                      ),
                    ));
              });
        } else {
          showModalBottomSheet(
              isDismissible: false,
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (builder) => const FractionallySizedBox(
                  heightFactor: 0.7, child: SetupPage())).then((val) async {});
        }
        // await MyApp.prefs.setBool("setup", true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final largeSC = checkLargeSC(context);

    final List<Widget> tabPages = <Widget>[
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            Home.showDropDown = false;
          });
        },
        child: FutureBuilder(
          future: getSubjectInfos(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final subjects = snapshot.data!;
              if (subjects.isNotEmpty) {
                subejctWidgetList = subjects
                    .asMap()
                    .entries
                    .map((e) => SubjectWidget(subInfo: e.value, index: e.key))
                    .toList();

                return ResponsiveGridList(
                  minItemWidth: 270,
                  horizontalGridMargin: 20,
                  horizontalGridSpacing: 30,
                  verticalGridSpacing: 10,
                  verticalGridMargin: 20,
                  children: subejctWidgetList,
                );
              } else {
                return Stack(alignment: Alignment.bottomCenter, children: [
                  Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Container(
                              margin: const EdgeInsets.all(15),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                  color: colorScheme.background,
                                  border:
                                      Border.all(color: colorScheme.outline),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10))),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("教科が一つもありません！",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20)),
                                    const Divider(),
                                    SizedBox.fromSize(
                                        size: const Size.fromHeight(10)),
                                    const Text("学習を開始するには、まずは教科を作成してください。",
                                        style: TextStyle(fontSize: 17))
                                  ])))),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("教科を作成する",
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      Icon(
                        Icons.keyboard_double_arrow_down,
                        size: 70,
                        color: colorScheme.primary,
                      ),
                    ],
                  )
                ]);
              }
            } else if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return const Center(
                child: Text("？"),
              );
            }
          },
        ),
      ),
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
        actions: <Widget>[
          IconButton(
              onPressed: () =>
                  showAboutDialog(context: context, children: <Widget>[
                    const Text(
                      "codename: mimosa",
                    )
                  ]),
              icon: const Icon(Icons.info))
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (selectedIndex) async {
          if (selectedIndex == 1) {
            late SubjectInfo? subInfo;
            if (largeSC) {
              subInfo = await showDialog(
                  context: context,
                  builder: (builder) {
                    return Dialog(
                        child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500.0),
                      child: tabPages[1],
                    ));
                  });
            } else {
              subInfo = await showModalBottomSheet<SubjectInfo>(
                  backgroundColor: Colors.transparent,
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return tabPages[1];
                  });
            }

            if (subInfo != null) {
              // 教科Widgetに追加
              setState(() {
                subejctWidgetList.add(SubjectWidget(
                    subInfo: subInfo!, index: subejctWidgetList.length));
              });

              // 教科ページへ移動
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: ((context) =>
                          SubjectOverview(subInfo: subInfo!))));
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

class SubjectWidget extends StatefulWidget {
  final SubjectInfo subInfo;
  final int index;

  const SubjectWidget({super.key, required this.subInfo, required this.index});

  @override
  State<SubjectWidget> createState() => _SubjectWidgetState();
}

class _SubjectWidgetState extends State<SubjectWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(alignment: Alignment.bottomRight, children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 150),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: (() => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (builder) =>
                          SubjectOverview(subInfo: widget.subInfo)))),
              onLongPress: () {
                setState(() {
                  Home.showDropDown = true;
                });
              },
              child: Text(
                widget.subInfo.title,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              )),
          const SizedBox(height: 50)
        ],
      ),
      IgnorePointer(
          ignoring: !Home.showDropDown,
          child: AnimatedOpacity(
              opacity: Home.showDropDown ? 1 : 0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                      color: colorScheme.background,
                      borderRadius: BorderRadius.circular(17)),
                  width: 200,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      leading: Icon(Icons.title, color: colorScheme.primary),
                      title: const Text("名前を変更"),
                      onTap: () {
                        setState(() {
                          Home.showDropDown = false;
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_forever,
                          color: colorScheme.primary),
                      title: const Text("削除"),
                      onTap: () async {
                        setState(() {
                          Home.showDropDown = false;
                        });

                        final confirm = await showDialog(
                            context: context,
                            builder: ((context) {
                              return AlertDialog(
                                title:
                                    Text('"${widget.subInfo.title}"を削除しますか？'),
                                content: const Text(
                                    '警告！その教科のセクションや問題などが全て削除されます！\nこの操作は取り消せません！'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('いいえ'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('はい'),
                                  ),
                                ],
                              );
                            }));

                        if (confirm ?? false) {
                          await removeSubject(widget.subInfo.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('削除しました')));

                          Home.removeSubjectWidget(context, widget.index);
                        }
                      },
                    )
                  ]))))
    ]);
  }
}
