import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:mimosa/main.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const List<String> _darkModeSelections = ["自動", "オン", "オフ"];
  int darkModeIndex = MyApp.themeMode == ThemeMode.system
      ? 0
      : (MyApp.themeMode == ThemeMode.dark ? 1 : 2);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text("ダークモード"),
          subtitle: const Text("自動では、端末の設定により変化します。\n(対応していない端末ではライトモードで表示)"),
          trailing: Text(
            _darkModeSelections[darkModeIndex],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          onTap: () {
            Picker(
                    adapter: PickerDataAdapter(pickerdata: _darkModeSelections),
                    changeToFirst: true,
                    onConfirm: (Picker picker, List value) {
                      MyApp.rootSetState(() {
                        switch (value.first) {
                          case 0:
                            MyApp.themeMode = ThemeMode.system;
                            break;
                          case 1:
                            MyApp.themeMode = ThemeMode.dark;
                            break;
                          case 2:
                            MyApp.themeMode = ThemeMode.light;
                            break;
                          default:
                            break;
                        }
                      });
                      setState(() {
                        darkModeIndex = value.first;
                      });
                    },
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    cancelText: "キャンセル",
                    confirmText: "決定")
                .showModal(context);
          },
        ),
        ElevatedButton.icon(
            onPressed: () {
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
                                onChanged: (val) {
                                  MyApp.rootSetState(() {
                                    MyApp.customColor = !val;
                                  });
                                })
                            : Container(),
                        MyApp.customColor
                            ? BlockPicker(
                                pickerColor: MyApp.seedColor,
                                onColorChanged: (color) {
                                  MyApp.rootSetState(() {
                                    MyApp.customColor = true;
                                    MyApp.seedColor = color;
                                  });
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
            icon: const Icon(Icons.color_lens),
            label: const Text("テーマ色を変更")),
        TextButton.icon(
          onPressed: ((() async {
            final path = (await getApplicationSupportDirectory()).path;
            final db = File(p.join(path, "study.db"));
            if (db.existsSync()) {
              db.deleteSync();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('削除したよ〜')));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('存在しないよ〜')));
            }
          })),
          icon: const Icon(Icons.delete_forever),
          label: const Text("study.dbを削除"),
        ),
      ],
    );
  }
}
