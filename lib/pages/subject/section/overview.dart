import 'package:flutter/material.dart';

import '../../../widgets/overview.dart';
import '../study.dart';
import '../../../db_helper.dart';
import './manage.dart';

class SectionPage extends StatefulWidget {
  final SectionInfo sectionInfo;

  const SectionPage({super.key, required this.sectionInfo});

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  final List<int> _questionListID = <int>[];
  final List<String> _questionListStr = <String>[];
  final List<bool?> _latestCorrects = [];
  late List<MiQuestion> miQuestions;
  late SectionInfo section;

  /// 現在のセクションの情報
  late SectionInfo secInfo;

  @override
  void initState() {
    super.initState();

    // セクション情報を読み込む
    secInfo = widget.sectionInfo;

    // 保存されている問題をリストに追加
    DataBaseHelper.getMiQuestions([widget.sectionInfo.tableID])
        .then((questions) {
      for (var question in questions) {
        _questionListID.add(question.id);
        setState(() {
          _latestCorrects.add(question.latestCorrect);
          _questionListStr.add(question.question);
        });
      }
      miQuestions = questions;
    });
  }

  /// Manageの結果からリストを更新する関数
  void updateList(List<dynamic>? manageResult) {
    // 何らかの変更があった場合のみ更新
    if (manageResult is List) {
      // [ID, 更新されたMiQuestion]
      final checkIndex = _questionListID.indexOf(manageResult[0]);
      final mi = (manageResult[1] as MiQuestion);

      // IDが存在する場合はMiQuestionなどを更新
      if (checkIndex != -1) {
        miQuestions[checkIndex] = mi;
        setState(() {
          _questionListStr[checkIndex] = mi.question;
        });
      } else {
        // IDが存在しない場合はIDなどを追加
        _questionListID.add(manageResult.first);
        miQuestions.add(mi);
        setState(() {
          _questionListStr.add(mi.question);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(secInfo.title),
          actions: <Widget>[
            IconButton(
                onPressed: ((() {
                  showModalBottomSheet(
                      context: context,
                      builder: (builder) {
                        return SizedBox(
                          height: 700,
                          child: SectionManagePage(sectionID: secInfo.tableID),
                        );
                      }).then(
                    (value) => updateList(value),
                  );
                })),
                icon: const Icon(Icons.add)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(7.0),
          child: SingleChildScrollView(
              child: Column(
            children: <Widget>[
              scoreBoard(
                  colorScheme,
                  secInfo.latestStudyMode == "test",
                  _latestCorrects.where((correct) => correct ?? false).length,
                  _latestCorrects
                      .where((correct) => !(correct ?? false))
                      .length),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                        onPressed: _questionListID.isNotEmpty
                            ? () async {
                                final record = await Navigator.of(context)
                                    .push<List<bool>>(MaterialPageRoute(
                                  builder: (context) => SectionStudyPage(
                                    secInfo: secInfo,
                                    miQuestions: miQuestions,
                                    testMode: false,
                                  ),
                                ));

                                if (record != null) {
                                  setState(() {
                                    secInfo = SectionInfo(
                                        subject: secInfo.subject,
                                        title: secInfo.title,
                                        latestStudyMode: "normal",
                                        tableID: secInfo.tableID);
                                  });
                                }
                              }
                            : null,
                        child: const Text("学習を開始する"),
                      )),
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                          onPressed: _questionListID.isNotEmpty
                              ? () async {
                                  final record = await Navigator.of(context)
                                      .push<List<int>>(MaterialPageRoute(
                                    builder: (context) => SectionStudyPage(
                                      secInfo: secInfo,
                                      miQuestions: miQuestions,
                                      testMode: true,
                                    ),
                                  ));

                                  if (record != null) {
                                    setState(() {
                                      secInfo = SectionInfo(
                                          subject: secInfo.subject,
                                          title: secInfo.title,
                                          latestStudyMode: "test",
                                          tableID: secInfo.tableID);
                                    });
                                  }
                                }
                              : null,
                          child: const Text("テストを開始する"))),
                ],
              ),
              const Divider(),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _questionListStr.length,
                  itemBuilder: ((context, index) => Dismissible(
                        key: Key(_questionListStr[index]),
                        onDismissed: (direction) async {
                          await DataBaseHelper.removeQuestion(
                              secInfo.tableID, _questionListID[index]);

                          _questionListID.removeAt(index);
                          setState(() {
                            _questionListStr.removeAt(index);
                          });

                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('削除しました')));
                        },
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('${index + 1}番目の問題を削除しますか？'),
                                content: const Text('この操作は取り消せません。'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('はい'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('いいえ'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const <Widget>[
                              Icon(Icons.delete),
                              Icon(Icons.delete)
                            ],
                          ),
                        ),
                        child: ListTile(
                            title: Text(
                              _questionListStr[index],
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(Icons.circle,
                                color: _latestCorrects[index] != null
                                    ? (_latestCorrects[index]!
                                        ? Colors.green
                                        : Colors.red)
                                    : Colors.grey),
                            onTap: ((() async {
                              final question =
                                  await DataBaseHelper.getMiQuestion(
                                      secInfo.tableID, _questionListID[index]);

                              final res = await showModalBottomSheet(
                                  context: context,
                                  builder: (builder) => SectionManagePage(
                                        sectionID: secInfo.tableID,
                                        miQuestion: question,
                                      ));
                              updateList(res);
                            }))),
                      ))),
            ],
          )),
        ));
  }
}
