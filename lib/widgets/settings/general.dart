import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/Picker.dart';

import '../../helper/common.dart';
import '../../main.dart';
import '../../pages/settings/cloud.dart';
import '../../utility.dart';

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
                          PickerDataAdapter(pickerData: darkModeSelections),
                      changeToFirst: true,
                      onConfirm: (Picker picker, List value) async {
                        late String prefsStr;
                        MyApp.rootSetState(context, () {
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
                    title: const Text("テーマカラーを選択"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyApp.supportDynamicColor
                            ? SwitchListTile(
                                title: const Text("端末で設定された色を利用"),
                                value: !(MyApp.customColor),
                                onChanged: (val) async {
                                  MyApp.rootSetState(context, () {
                                    MyApp.customColor = !val;
                                  });
                                  await MyApp.prefs
                                      .setBool("CustomColor", !val);
                                })
                            : Container(),
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: SingleChildScrollView(
                                child: MyApp.customColor
                                    ? ColorPicker(
                                        color: MyApp.seedColor,
                                        pickersEnabled: const <ColorPickerType,
                                            bool>{
                                          ColorPickerType.primary: false,
                                          ColorPickerType.accent: true
                                        },
                                        enableShadesSelection: false,
                                        borderRadius: 25,
                                        height: 45,
                                        width: 45,
                                        spacing: 15,
                                        runSpacing: 15,
                                        onColorChanged: (color) async {
                                          MyApp.rootSetState(context, () {
                                            MyApp.customColor = true;
                                            MyApp.seedColor = color;
                                          });
                                          await MyApp.prefs
                                              .setBool("CustomColor", true);
                                          await MyApp.prefs
                                              .setInt("SeedColor", color.value);
                                        })
                                    : Container())),
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
              title: const Text("学習データをバックアップ (ローカル)"),
              subtitle: const Text("学習帳データを任意の場所にバックアップします。"),
              trailing: Icon(
                Icons.download,
                color: colorScheme.primary,
              ),
              onTap: () async {
                final dialogRes = await showDialog<bool>(
                    context: context,
                    builder: (builder) => const WarningDialog(
                          content:
                              "バックアップしたファイルを私的な目的以外(他人に共有するなど)で利用した場合、法令や内部規則などの違反行為となり罰せられる可能性があります。\nこの機能を利用したことにより利用者が損害を被った場合でも、Leasyの開発者は当該損害に関して一切責任を負いません。\nまた、開発者などがこの機能が不正に利用されていることを発見した場合、然るべき機関に報告することがあります。\nこれらに同意しますか？",
                          count: 15,
                        ));
                if (!mounted || !(dialogRes ?? false)) return;

                final res = await backupDataBase().catchError((e) async {
                  await showDialog(
                      context: context,
                      builder: (builder) => AlertDialog(
                            title: const Text("エラー"),
                            content: Text(
                                "エラーが発生したため、データをバックアップ出来ませんでした。\n詳細:${e.toString()}"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("OK"))
                            ],
                          ));
                  // DB再読み込み
                  await loadStudyDataBase();
                  return false;
                });
                if (!res || !mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("データを保存しました。")));
              },
            ),
            ListTile(
                title: const Text("クラウド同期"),
                subtitle:
                    const Text("学習帳データをクラウドサービスに保存し、複数の端末でも同じ学習帳を利用できるようにします。"),
                trailing: Icon(
                  Icons.cloud,
                  color: colorScheme.primary,
                ),
                onTap: () async {
                  if (checkLargeSC(context)) {
                    await showDialog(
                        context: context,
                        builder: (builder) {
                          return Dialog(
                              child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700.0),
                            child: const CloudSyncPage(),
                          ));
                        });
                  } else {
                    await showModalBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (context) => const CloudSyncPage());
                  }
                }),
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
                  final res = await showDialog<bool>(
                      context: context,
                      builder: (builder) => const WarningDialog(
                          content:
                              "この操作を行うと、今までの学習データが全て削除されます。\n削除した学習データ復元できません。\n本当に削除しますか？"));
                  if (!(res ?? false)) return;

                  try {
                    await deleteStudyDataBase();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('データは削除できませんでした。詳細: $e')));
                    return;
                  }
                  willReset("削除しました。3秒後にアプリを再起動します...");
                }),
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
    if (!mounted) return;

    MyApp.resetApp(context);
  }
}

/// 警告ダイアログ
class WarningDialog extends StatefulWidget {
  const WarningDialog({
    super.key,
    this.titile = "警告",
    required this.content,
    this.count = 5,
    this.allButtonCount = false,
    this.yesButtonText = "はい",
    this.noButtonText = "いいえ",
  });

  // タイトル
  final String titile;
  // 警告文
  final String content;

  // ボタンを解放するまでの秒数
  final int count;
  // 全てのボタンに制限を設けるか
  final bool allButtonCount;

  // Trueを返すボタンのテキスト
  final String yesButtonText;
  // Falseを返すボタンのテキスト
  final String noButtonText;

  @override
  State<WarningDialog> createState() => _WarningDialogState();
}

class _WarningDialogState extends State<WarningDialog> {
  late String yesButtonText;
  late String noButtonText;
  bool openButton = false;

  late int count;
  late bool allButtonCount;

  late Timer timer;

  @override
  void initState() {
    super.initState();

    count = widget.count;
    allButtonCount = widget.allButtonCount;

    yesButtonText = "${widget.yesButtonText} ($count)";
    noButtonText = '${widget.noButtonText}${allButtonCount ? " ($count)" : ""}';

    // 待たせるTimer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count = count - 1;
      if (count == 0) {
        setState(() {
          yesButtonText = widget.yesButtonText;
          noButtonText = widget.noButtonText;
          openButton = true;
        });
        timer.cancel();
      } else {
        setState(() {
          yesButtonText = "${widget.yesButtonText} ($count)";
          noButtonText =
              '${widget.noButtonText}${allButtonCount ? " ($count)" : ""}';
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void onFalse() {
    timer.cancel();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titile),
      content: Text(widget.content),
      actions: [
        TextButton(
            // 待ってからボタンを押せるようにする
            onPressed: openButton
                ? () {
                    Navigator.pop(context, true);
                  }
                : null,
            child: Text(yesButtonText)),
        TextButton(
            onPressed: widget.allButtonCount
                ? openButton
                    ? onFalse
                    : null
                : onFalse,
            child: Text(noButtonText)),
      ],
    );
  }
}
