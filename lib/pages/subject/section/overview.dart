import 'package:flutter/material.dart';

import '../../../helper/question.dart';
import '../../../widgets/overview.dart';
import '../../../class/section.dart';
import '../../../class/question.dart';
import '../study.dart';
import './manage.dart';
import '../../../utility.dart';

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

  // 前回間違えた問題のみ学習する
  bool onlyIncorrect = true;

  @override
  void initState() {
    super.initState();

    // セクション情報を読み込む
    secInfo = widget.sectionInfo;

    // 保存されている問題をリストに追加
    getMiQuestions([widget.sectionInfo.tableID]).then((questions) {
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
  void updateList(MiQuestion? newQuestion) {
    // 何らかの変更があった場合のみ更新
    if (newQuestion != null) {
      final checkIndex = _questionListID.indexOf(newQuestion.id);

      // IDが存在する場合はMiQuestionなどを更新
      if (checkIndex != -1) {
        miQuestions[checkIndex] = newQuestion;
        setState(() {
          _questionListStr[checkIndex] = newQuestion.question;
        });
      } else {
        // IDが存在しない場合はIDなどを追加
        _questionListID.add(newQuestion.id);
        _latestCorrects.add(null);
        miQuestions.add(newQuestion);
        setState(() {
          _questionListStr.add(newQuestion.question);
        });
      }
    }
  }

  // 学習結果から記録を更新する
  void updateRecord(Map<int, bool>? record, bool isTest) async {
    if (record == null) return;

    final latestStudyMode = isTest ? "test" : "normal";
    setState(() {
      secInfo = SectionInfo(
          subjectID: secInfo.tableID,
          title: secInfo.title,
          latestStudyMode: latestStudyMode,
          tableID: secInfo.tableID);
    });

    // DBに記録を保存
    await updateSectionRecord(secInfo.tableID, latestStudyMode);

    // 正解記録を適切な場所に保存する
    record.forEach((id, correct) async {
      await updateQuestionRecord(id, correct);
      setState(() {
        _latestCorrects[
            miQuestions.indexWhere((mi) => mi.id.compareTo(id) == 0)] = correct;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(secInfo.title),
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
                      child: FilledButton(
                        onPressed: _questionListID.isNotEmpty
                            ? () async {
                                // 不正解のみの場合、不正解の問題のみ送る
                                final sendQs = onlyIncorrect
                                    ? miQuestions
                                        .where((mi) =>
                                            !(mi.latestCorrect ?? false))
                                        .toList()
                                    : miQuestions;
                                if (sendQs.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              '全ての問題が正解しているため、学習モードは実行されません。\nテストを行うか、不正解問題のみ学習をオフにしてください。')));
                                  return;
                                }

                                updateRecord(
                                    await Navigator.of(context)
                                        .push<Map<int, bool>>(MaterialPageRoute(
                                      builder: (context) => SectionStudyPage(
                                        secInfo: secInfo,
                                        miQuestions: sendQs,
                                        testMode: false,
                                      ),
                                    )),
                                    false);
                              }
                            : null,
                        child: const Text("学習を開始する"),
                      )),
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                          onPressed: _questionListID.isNotEmpty
                              ? () async {
                                  updateRecord(
                                      await Navigator.of(context)
                                          .push<Map<int, bool>>(
                                              MaterialPageRoute(
                                        builder: (context) => SectionStudyPage(
                                          secInfo: secInfo,
                                          miQuestions: miQuestions,
                                          testMode: true,
                                        ),
                                      )),
                                      true);
                                }
                              : null,
                          child: const Text("テストを開始する"))),
                ],
              ),
              SwitchListTile(
                  title: const Text("不正解・新規作成の問題のみ学習"),
                  secondary: Icon(
                    Icons.error,
                    color: colorScheme.brightness == Brightness.light
                        ? Colors.orange
                        : Colors.yellow,
                  ),
                  subtitle: const Text("テストモードでは適用されませんが、結果は反映されます。"),
                  value: onlyIncorrect,
                  onChanged: (val) => setState(() {
                        onlyIncorrect = val;
                      })),
              const Divider(),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _questionListStr.length,
                  itemBuilder: ((context, index) => Dismissible(
                        key: Key(_questionListStr[index]),
                        onDismissed: (direction) async {
                          await removeQuestion(_questionListID[index]);

                          _questionListID.removeAt(index);
                          miQuestions.removeAt(index);
                          setState(() {
                            _questionListStr.removeAt(index);
                            _latestCorrects.removeAt(index);
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
                                  await getMiQuestion(_questionListID[index]);

                              late MiQuestion? newMi;
                              if (checkLargeSC(context)) {
                                newMi = await showDialog(
                                    context: context,
                                    builder: (builder) {
                                      return Dialog(
                                          child: FractionallySizedBox(
                                        widthFactor: 0.6,
                                        child: SectionManagePage(
                                          sectionID: secInfo.tableID,
                                          miQuestion: question,
                                        ),
                                      ));
                                    });
                              } else {
                                newMi = await showModalBottomSheet(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (builder) {
                                      return SectionManagePage(
                                        sectionID: secInfo.tableID,
                                        miQuestion: question,
                                      );
                                    });
                              }
                              updateList(newMi);
                            }))),
                      ))),
            ],
          )),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: ((() {
            if (checkLargeSC(context)) {
              showDialog(
                  context: context,
                  builder: (builder) {
                    return Dialog(
                        child: FractionallySizedBox(
                      widthFactor: 0.6,
                      child: SectionManagePage(
                        sectionID: secInfo.tableID,
                      ),
                    ));
                  }).then((value) => updateList(value));
            } else {
              showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (builder) {
                    return SectionManagePage(
                      sectionID: secInfo.tableID,
                    );
                  }).then(
                (value) => updateList(value),
              );
            }
          })),
          tooltip: "問題を作成",
          child: const Icon(Icons.add),
        ));
  }
}
