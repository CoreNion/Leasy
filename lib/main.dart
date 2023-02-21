import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/home.dart';

void main() async {
  sqfliteFfiInit();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
