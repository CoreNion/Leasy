import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
  static final List<String> subejctTitleList = [];

  @override
  void initState() {
    super.initState();

    DataBaseHelper.getSubjectTitles().then((titles) {
      // 教科のタイトルを取得次第、Widgetを作成してリストに入れ、ホームのトップ画面に表示する
      for (var i = 0; i < titles.length; i++) {
        setState(() {
          subejctTitleList.add(titles[i]);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabPages = <Widget>[
      // 教科一覧ページ
      ResponsiveGridList(
        minItemWidth: 270,
        horizontalGridMargin: 20,
        horizontalGridSpacing: 30,
        verticalGridSpacing: 30,
        verticalGridMargin: 20,
        children: subejctTitleList
            .asMap()
            .entries
            .map((e) => subjectWidget(e.value, e.key))
            .toList(),
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
            showBarModalBottomSheet<String>(
                context: context,
                builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(pageTitles[selectedIndex]),
                        automaticallyImplyLeading: false,
                        leading: IconButton(
                            onPressed: (() => Navigator.of(context).pop()),
                            icon: const Icon(Icons.expand_more)),
                      ),
                      body: tabPages[1],
                    )).then((createdSubTitle) {
              if (createdSubTitle != null) {
                // 教科Widgetに追加
                setState(() {
                  subejctTitleList.add(createdSubTitle);
                });

                // 教科ページへ移動
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) =>
                            SubjectOverview(title: createdSubTitle))));
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
  Widget subjectWidget(String title, int index) {
    return Builder(
      builder: (context) => Stack(
        alignment: Alignment.topLeft,
        children: [
          // その教科のページに移動するボタン
          Container(
            margin: const EdgeInsets.only(top: 15, left: 15),
            child: MaterialButton(
              minWidth: double.infinity,
              height: 150,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onPressed: (() => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (builder) => SubjectOverview(title: title)))),
              onLongPress: () {},
              color: Colors.blueAccent,
              child: Text(
                title,
              ),
            ),
          ),
          // 教科削除ボタン
          Positioned(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.remove),
                color: Colors.black,
                onPressed: () async {
                  final confirm = await showDialog(
                      context: context,
                      builder: ((context) {
                        return AlertDialog(
                          title: Text('"$title"を削除しますか？'),
                          content: const Text(
                              '警告！その教科のセクションや問題などが全て削除されます！\nこの操作は取り消せません！'),
                          actions: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('いいえ'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('はい'),
                            ),
                          ],
                        );
                      }));

                  if (confirm) {
                    await DataBaseHelper.removeSubject(title);

                    // 教科一覧Widgetから削除
                    setState(() {
                      subejctTitleList.removeAt(index);
                    });
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('削除しました')));
                  }
                },
                splashRadius: 0.1,
              ),
            ),
          )
        ],
      ),
    );
  }
}
