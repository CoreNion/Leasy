import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/pages/subject/section/study.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../db_helper.dart';
import './manage.dart';

class SectionPage extends StatefulHookConsumerWidget {
  final Section sectionInfo;

  const SectionPage({super.key, required this.sectionInfo});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SectionPageState();
}

class _SectionPageState extends ConsumerState<SectionPage> {
  final List<int> _questionListID = <int>[];
  final List<String> _questionListStr = <String>[];
  late List<MiQuestion> miQuestions;
  late Section section;

  @override
  void initState() {
    super.initState();

    // 保存されている問題をリストに追加
    DataBaseHelper.getMiQuestions(widget.sectionInfo.tableID).then((questions) {
      for (var question in questions) {
        _questionListID.add(question.id);
        setState(() => _questionListStr.add(question.question));
      }
      miQuestions = questions;
    });
  }

  final shape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  );

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
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.sectionInfo.title),
          actions: <Widget>[
            IconButton(
                onPressed: ((() {
                  showBarModalBottomSheet(
                      context: context,
                      shape: shape,
                      builder: (builder) => SectionManagePage(
                          sectionID: widget.sectionInfo.tableID)).then(
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
              Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 7.0),
                      child: Text(
                        "前回の${widget.sectionInfo.latestStudyMode == "test" ? "テスト" : "学習"}の結果",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Text(
                          "正解: ${widget.sectionInfo.latestCorrect}問",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "不正解: ${widget.sectionInfo.latestIncorrect}問",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                        onPressed: _questionListID.isNotEmpty
                            ? () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => SectionStudyPage(
                                    sectionID: widget.sectionInfo.tableID,
                                    sectionTitle: widget.sectionInfo.title,
                                    miQuestions: miQuestions,
                                    testMode: false,
                                  ),
                                ))
                            : null,
                        child: const Text("学習を開始する"),
                      )),
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                          onPressed: _questionListID.isNotEmpty
                              ? () =>
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => SectionStudyPage(
                                      sectionID: widget.sectionInfo.tableID,
                                      sectionTitle: widget.sectionInfo.title,
                                      miQuestions: miQuestions,
                                      testMode: true,
                                    ),
                                  ))
                              : null,
                          child: const Text("テストを開始する"))),
                ],
              ),
              const Divider(),
              // 要検討: セクション一覧のListViewとWidgetを共通化
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _questionListStr.length,
                  itemBuilder: ((context, index) => Dismissible(
                        key: Key(_questionListStr[index]),
                        onDismissed: (direction) async {
                          await DataBaseHelper.removeQuestion(
                              widget.sectionInfo.tableID,
                              _questionListID[index]);

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
                            onTap: ((() async {
                              final question =
                                  await DataBaseHelper.getMiQuestion(
                                      widget.sectionInfo.tableID,
                                      _questionListID[index]);

                              final res = await showBarModalBottomSheet(
                                  context: context,
                                  shape: shape,
                                  builder: (builder) => SectionManagePage(
                                        sectionID: widget.sectionInfo.tableID,
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
