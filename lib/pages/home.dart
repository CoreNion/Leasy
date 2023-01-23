import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'create.dart';
import 'setting.dart';
import 'top.dart';

class Home extends StatefulHookConsumerWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int index = 0;
  final List<Widget> tabPages = const <Widget>[
    TopPage(),
    CreateSubjectPage(),
    SettingPage(),
  ];
  final List<String> pageTitles = const <String>[
    "Leasy",
    "教科を新規作成する",
    "設定",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageTitles[index])),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (selectedIndex) {
          if (selectedIndex == 1) {
            // 教科の作成Modelを表示
            showBarModalBottomSheet(
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
                    ));
          } else {
            setState(() => index = selectedIndex);
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
        selectedIndex: index,
      ),
      body: tabPages[index],
    );
  }
}
