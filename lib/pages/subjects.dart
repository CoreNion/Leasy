import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mimosa/widgets/overview.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../class/subject.dart';
import '../helper/common.dart';
import '../helper/subject.dart';
import './subject/overview.dart';

import '../helper/dummy.dart' if (dart.library.html) 'dart:html' as html;

class SubjectListPage extends StatefulWidget {
  const SubjectListPage({super.key});

  @override
  State<SubjectListPage> createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  /// 教科Widgetのリスト
  static List<Widget> subejctWidgetList = [];

  /// ボタンが押された時のタップ位置
  late Offset tapPosition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return FutureBuilder(
      future: getSubjectInfos(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final subjects = snapshot.data!;
          if (subjects.isNotEmpty) {
            /* 教科が存在する場合の処理 */

            // 教科Widgetのリストに、各教科のWidgetを作成して追加
            subejctWidgetList = subjects.asMap().entries.map((e) {
              SubjectInfo currentInfo = e.value;

              // 長押しや右クリックした時に出るメニューのアイテム
              final menuItems = <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  child: Wrap(
                    spacing: 10,
                    children: <Widget>[
                      Icon(Icons.title, color: colorScheme.primary),
                      const Text('名前を変更'),
                    ],
                  ),
                  onTap: () async {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final formKey = GlobalKey<FormState>();

                      late String newTitle;
                      final res = await showDialog<bool?>(
                          context: context,
                          builder: (builder) {
                            return AlertDialog(
                              title: const Text("新しい名前を入力"),
                              actions: [
                                TextButton(
                                    onPressed: (() =>
                                        Navigator.pop(context, false)),
                                    child: const Text("キャンセル")),
                                TextButton(
                                    onPressed: (() {
                                      if (formKey.currentState!.validate()) {
                                        Navigator.pop(context, true);
                                      }
                                    }),
                                    child: const Text("決定")),
                              ],
                              content: Form(
                                key: formKey,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: "教科名",
                                      icon: Icon(Icons.book),
                                      hintText: "教科名を入力"),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "教科名を入力してください";
                                    } else if (value == currentInfo.title) {
                                      return "新しい教科名を入力してください";
                                    } else {
                                      newTitle = value;
                                      return null;
                                    }
                                  },
                                ),
                              ),
                            );
                          });
                      if (!(res ?? false)) return;

                      await renameSubjectName(currentInfo.id, newTitle);

                      setState(() {
                        currentInfo = SubjectInfo(
                            title: newTitle,
                            id: currentInfo.id,
                            latestCorrect: currentInfo.latestCorrect,
                            latestIncorrect: currentInfo.latestIncorrect);
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('名前を変更しました')));
                      }
                    });
                  },
                ),
                PopupMenuItem<String>(
                  child: Wrap(
                    spacing: 10,
                    children: <Widget>[
                      Icon(Icons.delete_forever, color: colorScheme.error),
                      const Text('削除'),
                    ],
                  ),
                  onTap: () async {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final confirm = await showDialog(
                          context: context,
                          builder: ((context) {
                            return AlertDialog(
                              title: Text('"${currentInfo.title}"を削除しますか？'),
                              content: const Text(
                                  '警告！その教科のセクションや問題などが全て削除されます！\nこの操作は取り消せません！'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('いいえ'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('はい'),
                                ),
                              ],
                            );
                          }));

                      if (confirm ?? false) {
                        await removeSubject(currentInfo.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('削除しました')));
                          setState(() {
                            subejctWidgetList.removeAt(e.key);
                          });
                        }
                      }
                    });
                  },
                ),
              ];

              return GestureDetector(
                onTapDown: (d) =>
                    setState(() => tapPosition = d.globalPosition),
                onSecondaryTapDown: (details) {
                  /* 右クリック時の処理 */
                  HapticFeedback.lightImpact();
                  showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          screenSize.width - details.globalPosition.dx,
                          screenSize.height - details.globalPosition.dy),
                      items: menuItems);
                },
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 150),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: (() {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) =>
                                SubjectOverview(subInfo: currentInfo)));
                  }),
                  onLongPress: () {
                    HapticFeedback.lightImpact();
                    showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                            tapPosition.dx,
                            tapPosition.dy,
                            screenSize.width - tapPosition.dx,
                            screenSize.height - tapPosition.dy),
                        items: menuItems);
                  },
                  child: Text(
                    currentInfo.title,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList();

            return ResponsiveGridList(
              minItemWidth: 270,
              horizontalGridMargin: 20,
              horizontalGridSpacing: 30,
              verticalGridMargin: 20,
              verticalGridSpacing: 30,
              children: subejctWidgetList,
            );
          } else {
            /* 教科が一つも無い時に表示する画面 */
            return Stack(alignment: Alignment.bottomCenter, children: [
              Align(
                  alignment: Alignment.center,
                  child: dialogLikeMessage(colorScheme, "教科が一つもありません！",
                      "学習を開始するには、最初に教科を作成してください。\n初めて利用する方は、まずはデモ教科を作成し操作に慣れることをおすすめします。",
                      actions: [
                        OutlinedButton(
                            onPressed: () async {
                              await useDemoFile();

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'デモ教科を作成しました！${kIsWeb ? "\n読み込みのために、数秒後にサイトを再読み込みします。" : ""}')));
                              setState(() {});

                              // Web版の場合はデータベースを完全に読み込むためにリロード
                              if (kIsWeb) {
                                Future.delayed(const Duration(seconds: 3), () {
                                  html.window.location.reload();
                                });
                              }
                            },
                            child: const Text("デモ教科を作成"))
                      ])),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("教科を作成する",
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 25,
                          fontWeight: FontWeight.bold)),
                  Icon(
                    Icons.keyboard_double_arrow_down,
                    size: 70,
                    color: colorScheme.primary,
                  ),
                ],
              )
            ]);
          }
        } else if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return const Center(
            child: Text("？"),
          );
        }
      },
    );
  }
}
