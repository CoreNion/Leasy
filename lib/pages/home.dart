import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../db_helper.dart';
import 'create.dart';
import 'setting.dart';
import 'subject/overview.dart';

class Home extends StatefulHookConsumerWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int pageIndex = 0;

  // トップに表示される教科のWidgetのリスト
  static List<Widget> subejctWidgetList = [];

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
                context: context,
                builder: (context) {
                  return SizedBox(
                    height: 250,
                    child: Scaffold(
                      appBar: AppBar(
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        title: Text(pageTitles[selectedIndex]),
                        automaticallyImplyLeading: false,
                        leading: IconButton(
                            onPressed: (() => Navigator.of(context).pop()),
                            icon: const Icon(Icons.expand_more)),
                      ),
                      body: tabPages[1],
                    ),
                  );
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
    return Builder(
      builder: (context) => Stack(
        alignment: Alignment.topLeft,
        children: [
          // その教科のページに移動するボタン
          MaterialButton(
            minWidth: double.infinity,
            height: 150,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onPressed: (() => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (builder) =>
                            SubjectOverview(subInfo: subInfo))).then((removed) {
                  if (removed != null && removed == true) {
                    setState(() {});
                  }
                })),
            color: Theme.of(context).colorScheme.onPrimary.withGreen(150),
            child: Text(
              subInfo.title,
            ),
          ),
        ],
      ),
    );
  }
}
