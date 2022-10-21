import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/pages/create.dart';
import 'package:mimosa/pages/top.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/setting.dart';

final titleTextProvider = StateProvider((_) => 'Mimosa');
final pageIndexProvider = StateProvider((_) => 0);

void main() async {
  sqfliteFfiInit();

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
        builder: ((lightDynamic, darkDynamic) => MaterialApp(
              title: 'Mimosa',
              theme: ThemeData(
                  colorScheme: lightDynamic != null
                      ? lightDynamic.harmonized()
                      : ColorScheme.fromSeed(
                          seedColor: Colors.blue, brightness: Brightness.light),
                  useMaterial3: true),
              darkTheme: ThemeData(
                  colorScheme: darkDynamic != null
                      ? darkDynamic.harmonized()
                      : ColorScheme.fromSeed(
                          seedColor: Colors.blue,
                          brightness: Brightness.dark,
                        ),
                  useMaterial3: true),
              home: const Home(),
            )));
  }
}

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
