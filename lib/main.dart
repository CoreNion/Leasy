import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static late SharedPreferences prefs;

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
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) async {
      final customColorKey = prefs.getBool("CustomColor");
      if (customColorKey != null) {
        MyApp.customColor = customColorKey;

        switch (prefs.getString("ThemeMode")) {
          case "system":
            MyApp.themeMode = ThemeMode.system;
            break;
          case "dark":
            MyApp.themeMode = ThemeMode.dark;
            break;
          case "light":
            MyApp.themeMode = ThemeMode.light;
            break;
          default:
        }

        MyApp.seedColor = Color(prefs.getInt("SeedColor")!);
      } else {
        // 初期化
        await prefs.setBool("CustomColor", false);
        await prefs.setString("ThemeMode", "system");
        await prefs.setInt("SeedColor", MyApp.seedColor.value);
      }

      MyApp.prefs = prefs;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyApp.rootSetState = setState;

    return DynamicColorBuilder(builder: ((lightDynamic, darkDynamic) {
      late ColorScheme lightScheme;
      late ColorScheme darkScheme;

      if (lightDynamic != null) {
        MyApp.supportDynamicColor = true;
      } else {
        MyApp.supportDynamicColor = false;
        MyApp.customColor = true;
      }

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

      // backgroundにDynamic Colorの色味を付ける (デフォルトだと真っ白)
      lightScheme =
          lightScheme.copyWith(background: lightScheme.onInverseSurface);

      return MaterialApp(
        title: 'Leasy',
        theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme.of(context)
                .copyWith(backgroundColor: lightScheme.onInverseSurface)),
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
