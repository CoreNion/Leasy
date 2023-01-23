import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'create.dart';
import 'setting.dart';
import 'top.dart';

final titleTextProvider = StateProvider((_) => 'Leasy');
final pageIndexProvider = StateProvider((_) => 0);

class Home extends StatefulHookConsumerWidget {
  const Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  Widget build(BuildContext context) {
    StateController<String> title = ref.watch(titleTextProvider.notifier);
    StateController<int> globalIndex = ref.watch(pageIndexProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(title.state)),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          setState(() => globalIndex.state = index);
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
            label: '問題を作成',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        selectedIndex: globalIndex.state,
      ),
      body: IndexedStack(
        index: globalIndex.state,
        children: const <Widget>[
          TopPage(),
          CreateSubjectPage(),
          SettingPage(),
        ],
      ),
    );
  }
}
