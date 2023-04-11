import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                return WillPopScope(
                    onWillPop: () async => false,
                    child: const Dialog(
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
              builder: (builder) => WillPopScope(
                  onWillPop: () async => false,
                  child: const FractionallySizedBox(
                      heightFactor: 0.7, child: SetupPage())));
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

              // 教科Widgetに追加
              setState(() {
                subejctWidgetList.add(SubjectWidget(
                    subInfo: subInfo, index: subejctWidgetList.length));
              });

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

class SubjectWidget extends StatefulWidget {
  final SubjectInfo subInfo;
  final int index;

  const SubjectWidget({super.key, required this.subInfo, required this.index});

  @override
  State<SubjectWidget> createState() => _SubjectWidgetState();
}

class _SubjectWidgetState extends State<SubjectWidget> {
  late SubjectInfo currentInfo;

  @override
  void initState() {
    super.initState();

    currentInfo = widget.subInfo;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(alignment: Alignment.bottomRight, children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
              onLongPress: () => setState(() {
                    HapticFeedback.lightImpact();
                    Home.showDropDown = true;
                  }),
              onSecondaryTapUp: (details) => setState(() {
                    Home.showDropDown = true;
                  }),
              child: FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 150),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: (() {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (builder) =>
                              SubjectOverview(subInfo: currentInfo)));
                }),
                child: Text(
                  currentInfo.title,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                ),
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
                      onTap: () async {
                        setState(() {
                          Home.showDropDown = false;
                        });

                        final formKey = GlobalKey<FormState>();
                        setState(() {
                          Home.showDropDown = false;
                        });

                        late String newTitle;
                        final res = await showDialog<bool?>(
                            context: context,
                            builder: (builder) {
                              return AlertDialog(
                                title: const Text("新しい名前を入力"),
                                actions: [
                                  TextButton(
                                      onPressed: (() =>
                                          Navigator.pop(context, false)),
                                      child: const Text("キャンセル")),
                                  TextButton(
                                      onPressed: (() {
                                        if (formKey.currentState!.validate()) {
                                          Navigator.pop(context, true);
                                        }
                                      }),
                                      child: const Text("決定")),
                                ],
                                content: Form(
                                  key: formKey,
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: "教科名",
                                        icon: Icon(Icons.book),
                                        hintText: "教科名を入力"),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "教科名を入力してください";
                                      } else if (value ==
                                          widget.subInfo.title) {
                                        return "新しい教科名を入力してください";
                                      } else {
                                        newTitle = value;
                                        return null;
                                      }
                                    },
                                  ),
                                ),
                              );
                            });
                        if (!(res ?? false)) return;

                        await renameSubjectName(widget.subInfo.id, newTitle);

                        setState(() {
                          currentInfo = SubjectInfo(
                              title: newTitle,
                              id: currentInfo.id,
                              latestCorrect: currentInfo.latestCorrect,
                              latestIncorrect: currentInfo.latestIncorrect);
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('名前を変更しました')));
                        }
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

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('削除しました')));
                            Home.removeSubjectWidget(context, widget.index);
                          }
                        }
                      },
                    )
                  ]))))
    ]);
  }
}
