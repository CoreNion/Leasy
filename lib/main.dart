import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import './helper/common.dart';
import 'pages/home.dart';

void main() async {
  if (kIsWeb || Platform.isIOS || Platform.isAndroid) {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  sqfliteFfiInit();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static late SharedPreferences prefs;

  // パッケージ情報
  static late PackageInfo packageInfo;

  /// アプリのColorSchemeで選択された色
  static Color seedColor = Colors.blue;

  /// 端末が動的な色に対応しているか
  static bool supportDynamicColor = false;

  /// アプリ側で設定された色を利用するかどうか
  static bool customColor = false;

  /// ThemeModeの設定
  static ThemeMode themeMode = ThemeMode.system;

  static void rootSetState(BuildContext context, Function fun) {
    context.findAncestorStateOfType<_MyAppState>()!.rootSetState(fun);
  }

  static Key rootKey = UniqueKey();

  static void resetApp(BuildContext context) {
    // メモリにある設定も削除
    MyApp.seedColor = Colors.blue;
    MyApp.supportDynamicColor = false;
    MyApp.customColor = false;
    MyApp.themeMode = ThemeMode.system;

    rootSetState(context, () {
      rootKey = UniqueKey();
    });
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void rootSetState(Function fun) {
    setState(() {
      fun();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
        key: MyApp.rootKey,
        child: FutureBuilder(
          future: SharedPreferences.getInstance().then((prefs) async {
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

            // データベースのロード
            await loadStudyDataBase();
            // バージョン情報のロード
            MyApp.packageInfo = await PackageInfo.fromPlatform();

            MyApp.prefs = prefs;
            return prefs;
          }),
          builder: (BuildContext context,
              AsyncSnapshot<SharedPreferences> snapshot) {
            if (snapshot.hasData) {
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
                          seedColor: MyApp.seedColor,
                          brightness: Brightness.light);
                  darkScheme = darkDynamic != null
                      ? darkDynamic.harmonized()
                      : ColorScheme.fromSeed(
                          seedColor: MyApp.seedColor,
                          brightness: Brightness.dark);
                } else {
                  lightScheme = ColorScheme.fromSeed(
                      seedColor: MyApp.seedColor, brightness: Brightness.light);
                  darkScheme = ColorScheme.fromSeed(
                      seedColor: MyApp.seedColor, brightness: Brightness.dark);
                }

                // backgroundにDynamic Colorの色味を付ける (デフォルトだと真っ白)
                lightScheme = lightScheme.copyWith(
                    background: lightScheme.onInverseSurface);

                // スプラッシュの削除
                if (kIsWeb || Platform.isIOS || Platform.isAndroid) {
                  FlutterNativeSplash.remove();
                }

                return MaterialApp(
                  title: 'Leasy',
                  theme: ThemeData(
                      colorScheme: lightScheme,
                      useMaterial3: true,
                      fontFamily: 'M PLUS 2',
                      scaffoldBackgroundColor: Colors.white,
                      appBarTheme: AppBarTheme.of(context).copyWith(
                          backgroundColor: lightScheme.onInverseSurface)),
                  darkTheme: ThemeData(
                      colorScheme: darkScheme,
                      fontFamily: 'M PLUS 2',
                      scaffoldBackgroundColor: Colors.black,
                      useMaterial3: true),
                  themeMode: MyApp.themeMode,
                  home: const Home(),
                );
              }));
            } else if (snapshot.connectionState != ConnectionState.done) {
              return Container(
                color: Colors.black,
              );
            } else {
              return const Text(
                "?",
              );
            }
          },
        ));
  }
}
