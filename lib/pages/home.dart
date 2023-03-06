import 'package:flutter/material.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../main.dart';
import '../db_helper.dart';
import '../class/subject.dart';
import './setup.dart';
import 'create.dart';
import 'setting.dart';
import 'subject/overview.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  // トップに表示される教科のWidgetのリスト
  static List<Widget> subejctWidgetList = [];

  @override
  void initState() {
    super.initState();

    if (!(MyApp.prefs.getBool("setup") ?? false)) {
      // 初回セットアップ(初期画面)を表示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 大画面デバイスではDialogで表示
        if (MediaQuery.of(context).size.width > 1000) {
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
    final List<Widget> tabPages = <Widget>[
      FutureBuilder(
        future: DataBaseHelper.getSubjectInfos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            subejctWidgetList = snapshot.data!
                .asMap()
                .entries
                .map((e) => subjectWidget(e.value, e.key))
                .toList();

            return ResponsiveGridList(
              minItemWidth: 270,
              horizontalGridMargin: 20,
              horizontalGridSpacing: 30,
              verticalGridSpacing: 30,
              verticalGridMargin: 20,
              children: subejctWidgetList,
            );
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
        onDestinationSelected: (selectedIndex) {
          if (selectedIndex == 1) {
            // 教科の作成Modelを表示
            showModalBottomSheet<String>(
                backgroundColor: Colors.transparent,
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) {
                  return tabPages[1];
                }).then((createdSubTitle) {
              if (createdSubTitle != null) {
                final subInfo = SubjectInfo(
                    title: createdSubTitle,
                    latestCorrect: 0,
                    latestIncorrect: 0);

                // 教科Widgetに追加
                setState(() {
                  subejctWidgetList
                      .add(subjectWidget(subInfo, subejctWidgetList.length));
                });

                // 教科ページへ移動
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) =>
                                SubjectOverview(subInfo: subInfo))))
                    .then((removed) {
                  if (removed != null && removed == true) {
                    setState(() {});
                  }
                });
              }
            });
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

  /// 教科Widgetのモデル
  Widget subjectWidget(SubjectInfo subInfo, int index) {
    return FilledButton(
        style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 150),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        onPressed: (() => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (builder) =>
                        SubjectOverview(subInfo: subInfo))).then((removed) {
              if (removed != null && removed == true) {
                setState(() {});
              }
            })),
        child: Text(
          subInfo.title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ));
  }
}
