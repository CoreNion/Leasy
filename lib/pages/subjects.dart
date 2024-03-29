import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mimosa/widgets/overview.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

import '../class/subject.dart';
import '../helper/demo.dart';
import '../helper/subject.dart';
import './subject/overview.dart';

class SubjectListPage extends StatefulWidget {
  const SubjectListPage({super.key});

  @override
  State<SubjectListPage> createState() => SubjectListPageState();
}

class SubjectListPageState extends State<SubjectListPage> {
  late Future<List<SubjectInfo>> getSubjectInfoTask;

  /// 教科Widgetのリスト
  List<Widget> subejctWidgetList = [];

  /// ボタンが押された時のタップ位置
  late Offset tapPosition;

  bool _demoLoading = false;

  @override
  void initState() {
    super.initState();
    getSubjectInfoTask = getSubjectInfos();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return FutureBuilder(
      future: getSubjectInfoTask,
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
                      bool loading = false;
                      final res = await showDialog<bool?>(
                          context: context,
                          barrierDismissible: false,
                          builder: (builder) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              return AlertDialog(
                                title: const Text("新しい名前を入力"),
                                actions: [
                                  TextButton(
                                      onPressed: !loading
                                          ? (() =>
                                              Navigator.pop(context, false))
                                          : null,
                                      child: const Text("キャンセル")),
                                  !loading
                                      ? TextButton(
                                          onPressed: (() async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              setState(() => loading = true);

                                              await renameSubjectName(
                                                  currentInfo.id, newTitle);
                                              if (!context.mounted) return;

                                              Navigator.pop(context, true);
                                            }
                                          }),
                                          child: const Text("決定"))
                                      : Container(
                                          width: 24,
                                          height: 24,
                                          padding: const EdgeInsets.all(2.0),
                                          child: CircularProgressIndicator(
                                            color: colorScheme.onSurface,
                                            strokeWidth: 3,
                                          ),
                                        ),
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
                          });
                      if (!(res ?? false)) return;

                      setState(() {
                        currentInfo = SubjectInfo(
                            title: newTitle,
                            id: currentInfo.id,
                            latestCorrect: currentInfo.latestCorrect,
                            latestIncorrect: currentInfo.latestIncorrect);
                        getSubjectInfoTask = getSubjectInfos();
                      });
                      BotToast.showSimpleNotification(title: "教科名を変更しました");
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
                        setState(() {
                          subjects.removeAt(e.key);
                          _demoLoading = true;
                        });

                        await removeSubject(currentInfo.id);

                        if (context.mounted) {
                          setState(() {
                            _demoLoading = false;
                          });
                          BotToast.showSimpleNotification(title: "教科を削除しました");
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
                                SubSecOverview(info: currentInfo)));
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
                        OutlinedButton.icon(
                            icon: _demoLoading
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: const EdgeInsets.all(2.0),
                                    child: CircularProgressIndicator(
                                      color: colorScheme.onSurface,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            onPressed: _demoLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _demoLoading = true;
                                    });
                                    await generateSubjectDemo();

                                    BotToast.showSimpleNotification(
                                      title: "デモ教科を作成しました！",
                                    );
                                    setState(() {
                                      _demoLoading = false;
                                      getSubjectInfoTask = getSubjectInfos();
                                    });
                                  },
                            label: const Text("デモ教科を作成"))
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
          return Align(
            alignment: Alignment.center,
            child: dialogLikeMessage(
              colorScheme,
              "エラーが発生しました",
              "教科情報が取得できませんでした。単語帳データが破損している可能性があります。\n詳細: ${snapshot.error.toString()}",
            ),
          );
        }
      },
    );
  }
}
