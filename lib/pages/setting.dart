import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_picker/Picker.dart';

import '../helper/common.dart';
import '../main.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.all(17),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: const <Widget>[
                        ScreenSettings(),
                        SizedBox(height: 25),
                        DataSettings()
                      ],
                    )))));
  }
}

/// 画面系の設定を行うWidget
class ScreenSettings extends StatefulWidget {
  const ScreenSettings({super.key});

  @override
  State<ScreenSettings> createState() => _ScreenSettingsState();
}

class _ScreenSettingsState extends State<ScreenSettings> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const List<String> darkModeSelections = ["自動", "オン", "オフ"];
    int darkModeIndex = MyApp.themeMode == ThemeMode.system
        ? 0
        : (MyApp.themeMode == ThemeMode.dark ? 1 : 2);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: colorScheme.background,
          border: Border.all(color: colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Column(
        children: [
          const Text(
            "外観",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Divider(),
          ListTile(
            title: const Text("ダークモード"),
            subtitle: const Text("自動では、端末の設定により変化します。\n(対応していない端末ではライトモードで表示)"),
            trailing: Text(
              darkModeSelections[darkModeIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onTap: () {
              Picker(
                      adapter:
                          PickerDataAdapter(pickerdata: darkModeSelections),
                      changeToFirst: true,
                      onConfirm: (Picker picker, List value) async {
                        late String prefsStr;
                        MyApp.rootSetState(() {
                          switch (value.first) {
                            case 0:
                              MyApp.themeMode = ThemeMode.system;
                              prefsStr = "system";
                              break;
                            case 1:
                              MyApp.themeMode = ThemeMode.dark;
                              prefsStr = "dark";
                              break;
                            case 2:
                              MyApp.themeMode = ThemeMode.light;
                              prefsStr = "light";
                              break;
                            default:
                              break;
                          }
                        });
                        setState(() {
                          darkModeIndex = value.first;
                        });

                        await MyApp.prefs.setString("ThemeMode", prefsStr);
                      },
                      backgroundColor: colorScheme.background,
                      textStyle: Theme.of(context).textTheme.titleLarge,
                      cancelText: "キャンセル",
                      confirmText: "決定")
                  .showModal(context);
            },
          ),
          ListTile(
            title: const Text("テーマ色"),
            subtitle: const Text("アプリの表示の基本となる色を設定します。"),
            trailing: Icon(Icons.circle, color: colorScheme.primary),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("テーマ色を選択"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyApp.supportDynamicColor
                            ? SwitchListTile(
                                title: const Text("端末で設定された色を利用"),
                                value: !(MyApp.customColor),
                                onChanged: (val) async {
                                  MyApp.rootSetState(() {
                                    MyApp.customColor = !val;
                                  });
                                  await MyApp.prefs
                                      .setBool("CustomColor", !val);
                                })
                            : Container(),
                        MyApp.customColor
                            ? BlockPicker(
                                pickerColor: MyApp.seedColor,
                                onColorChanged: (color) async {
                                  MyApp.rootSetState(() {
                                    MyApp.customColor = true;
                                    MyApp.seedColor = color;
                                  });

                                  await MyApp.prefs
                                      .setBool("CustomColor", true);
                                  await MyApp.prefs
                                      .setInt("SeedColor", color.value);
                                })
                            : Container(),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// データ系の設定を行うWidget
class DataSettings extends StatefulWidget {
  const DataSettings({super.key});

  @override
  State<DataSettings> createState() => _DataSettingsState();
}

class _DataSettingsState extends State<DataSettings> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final boxDeco = BoxDecoration(
        color: colorScheme.background,
        border: Border.all(color: colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(10)));

    return Container(
        padding: const EdgeInsets.all(5),
        decoration: boxDeco,
        child: Column(
          children: [
            const Text(
              "データ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Divider(),
            ListTile(
                title: const Text("設定を初期化"),
                subtitle: const Text("設定を初期化します。学習データは削除されません。"),
                trailing: Icon(
                  Icons.settings,
                  color: colorScheme.primary,
                ),
                onTap: () async {
                  showDialog(
                      context: context,
                      builder: (builder) {
                        return AlertDialog(
                          title: const Text("確認"),
                          content: const Text(
                              "テーマカラーなどの設定を全て削除します。よろしいですか？\n＊学習データは削除されません。"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  MyApp.prefs.clear().then((value) {
                                    willReset("削除しました。3秒後にアプリを再起動します...");
                                  });
                                },
                                child: const Text("はい")),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("いいえ")),
                          ],
                        );
                      }).then((value) {});
                }),
            ListTile(
                title: const Text("学習データをリセット"),
                subtitle: const Text("学習データを全て削除します。この操作は元に戻せません！"),
                trailing: Icon(
                  Icons.delete_forever,
                  color: colorScheme.primary,
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final res = await showDialog<bool>(
                      context: context,
                      builder: (builder) => const RemoveDialog());
                  if (!(res ?? false)) return;

                  try {
                    await deleteStudyDataBase();
                  } catch (e) {
                    messenger.showSnackBar(
                        SnackBar(content: Text('データは削除できませんでした。詳細: $e')));
                    return;
                  }
                  willReset("削除しました。3秒後にアプリを再起動します...");
                }),
            ListTile(
              title: const Text("アプリを再起動"),
              subtitle: const Text("アプリを再起動します。"),
              trailing: Icon(
                Icons.refresh,
                color: colorScheme.primary,
              ),
              onTap: () {
                willReset("3秒後にアプリを再起動します...");
              },
            )
          ],
        ));
  }

  /// 削除しましたというダイアログを出して、3秒後にリセットする関数
  Future<void> willReset(String title) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (builder) {
          return WillPopScope(
              onWillPop: null,
              child: AlertDialog(
                title: Text(title),
              ));
        });

    await Future.delayed(const Duration(seconds: 3));
    MyApp.resetApp();
  }
}

/// データベース削除時に出てくるダイアログ
class RemoveDialog extends StatefulWidget {
  const RemoveDialog({super.key});

  @override
  State<RemoveDialog> createState() => _RemoveDialogState();
}

class _RemoveDialogState extends State<RemoveDialog> {
  String yesButtonText = "はい (5)";
  bool openYesButton = false;

  int count = 5;
  late Timer timer;

  @override
  void initState() {
    super.initState();

    // 5秒待たせるTimer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count = count - 1;
      if (count == 0) {
        setState(() {
          yesButtonText = "はい";
          openYesButton = true;
        });
        timer.cancel();
      } else {
        setState(() {
          yesButtonText = "はい ($count)";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("警告"),
      content: const Text(
          "この操作を行うと、今までの学習データが全て削除されます。\n削除した学習データ復元できません。\n本当に削除しますか？"),
      actions: [
        TextButton(
            // 5秒待ってからボタンを押せるようにする
            onPressed: openYesButton
                ? () {
                    Navigator.pop(context, true);
                  }
                : null,
            child: Text(yesButtonText)),
        TextButton(
            onPressed: () {
              timer.cancel();
              Navigator.pop(context, false);
            },
            child: const Text("いいえ")),
      ],
    );
  }
}
