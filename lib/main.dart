import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/home.dart';

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
              title: 'Leasy',
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
                  scaffoldBackgroundColor: Colors.black,
                  useMaterial3: true),
              home: const Home(),
            )));
  }
}
