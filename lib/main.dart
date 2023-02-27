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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// アプリのColorSchemeで選択された色
  static Color seedColor = Colors.blue;

  /// 端末が動的な色に対応しているか
  static bool supportDynamicColor = false;

  /// アプリ側で設定された色を利用するかどうか
  static bool customColor = false;

  /// ThemeModeの設定
  static ThemeMode themeMode = ThemeMode.system;

  static Function rootSetState = () {};

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    MyApp.rootSetState = setState;

    return DynamicColorBuilder(builder: ((lightDynamic, darkDynamic) {
      late ColorScheme lightScheme;
      late ColorScheme darkScheme;

      lightDynamic != null
          ? MyApp.supportDynamicColor = true
          : MyApp.supportDynamicColor = false;

      if (!MyApp.customColor) {
        lightScheme = lightDynamic != null
            ? lightDynamic.harmonized()
            : ColorScheme.fromSeed(
                seedColor: MyApp.seedColor, brightness: Brightness.light);
        darkScheme = darkDynamic != null
            ? darkDynamic.harmonized()
            : ColorScheme.fromSeed(
                seedColor: MyApp.seedColor, brightness: Brightness.dark);
      } else {
        lightScheme = ColorScheme.fromSeed(
            seedColor: MyApp.seedColor, brightness: Brightness.light);
        darkScheme = ColorScheme.fromSeed(
            seedColor: MyApp.seedColor, brightness: Brightness.dark);
      }

      return MaterialApp(
        title: 'Leasy',
        theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
        darkTheme: ThemeData(
            colorScheme: darkScheme,
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true),
        themeMode: MyApp.themeMode,
        home: const Home(),
      );
    }));
  }
}
