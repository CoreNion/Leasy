import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mimosa/class/study.dart';
import 'package:mimosa/pages/subject/study_setting.dart';
import 'package:mimosa/widgets/dialog.dart';

import '../../../helper/question.dart';
import '../../../helper/section.dart';
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
  bool loading = true;
  Map<int, MiQuestionSummary> _questionSummaries = {};

  /// 現在のセクションの情報
  late SectionInfo secInfo;

  @override
  void initState() {
    super.initState();

    // セクション情報を読み込む
    secInfo = widget.sectionInfo;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 保存されている問題をMapに追加
      final summaries =
          await getMiQuestionSummaries(widget.sectionInfo.tableID);
      Map<int, MiQuestionSummary> res = {};
      for (var qs in summaries) {
        res.addAll({qs.id: qs});
      }
      if (!mounted) return;

      setState(() {
        _questionSummaries = res;
        loading = false;
      });
    });
  }

  void _endLoading() {
    if (!mounted) return;
    setState(() => loading = false);
  }

  /// Manageの結果からQuestionを更新する関数
  void updateQuestion(MiQuestion? newQuestion) {
    setState(() => loading = true);
    // 何らかの変更があった場合のみ更新
    if (newQuestion != null) {
      final id = newQuestion.id;

      if (_questionSummaries.containsKey(id)) {
        // 既存の問題の場合はMiQuestionなどを更新
        updateMiQuestion(id, newQuestion).then((_) => _endLoading());
      } else {
        // IDが存在しない場合は作成
        createQuestion(newQuestion).then((_) => _endLoading());
      }
      if (!mounted) return;

      setState(() {
        _questionSummaries[id] = MiQuestionSummary(
            id: id,
            question: newQuestion.question,
            totalCorrect: 0,
            totalInCorrect: 0,
            latestCorrect: null);
      });
    } else {
      _endLoading();
    }
  }

  // 学習結果から記録を更新する
  Future<void> updateRecord(Map<int, bool>? records, bool isTest) async {
    if (records == null) return;
    final latestStudyMode = isTest ? "test" : "normal";

    setState(() {
      loading = true;
      secInfo = SectionInfo(
          subjectID: secInfo.tableID,
          title: secInfo.title,
          latestStudyMode: latestStudyMode,
          tableID: secInfo.tableID);
    });

    // UI上の問題の記録を更新
    for (var record in records.entries) {
      final id = record.key;
      final correct = record.value;

      final qs = _questionSummaries[id]!;
      final newQs = MiQuestionSummary(
          id: id,
          question: qs.question,
          totalCorrect: qs.totalCorrect + (correct ? 1 : 0),
          totalInCorrect: qs.totalInCorrect + (correct ? 0 : 1),
          latestCorrect: correct);

      setState(() {
        _questionSummaries[id] = newQs;
      });
    }

    // DBにセクションの記録を保存
    final secTask = updateSectionRecord(secInfo.tableID, latestStudyMode);
    // DBの各問題の記録を更新
    final queTask = updateQuestionRecords(records);
    // 裏で実行
    Future.wait([secTask, queTask]).then((value) {
      setState(() {
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(secInfo.title),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              height: 20,
              width: 20,
              child: loading ? const CircularProgressIndicator() : null,
            )
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
                  _questionSummaries.values
                      .where((qs) => qs.latestCorrect ?? false)
                      .length,
                  _questionSummaries.values
                      .where((qs) => !(qs.latestCorrect ?? false))
                      .length),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: FilledButton(
                        onPressed: _questionSummaries.isNotEmpty
                            ? () async {
                                await doStudy(false);
                              }
                            : null,
                        child: const Text("学習を開始する"),
                      )),
                  Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ElevatedButton(
                          onPressed: _questionSummaries.isNotEmpty
                              ? () async {
                                  await doStudy(true);
                                }
                              : null,
                          child: const Text("テストを開始する"))),
                ],
              ),
              const Divider(),
              _questionSummaries.isNotEmpty
                  ? ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _questionSummaries.length,
                      itemBuilder: ((context, index) {
                        final id = _questionSummaries.keys.elementAt(index);
                        final qs = _questionSummaries.values.elementAt(index);

                        // 正解率を計算
                        final ratio = qs.totalCorrect == 0
                            ? 0.toDouble()
                            : qs.totalCorrect /
                                (qs.totalCorrect + qs.totalInCorrect);

                        return Dismissible(
                          key: Key(id.toString()),
                          confirmDismiss: (direction) async {
                            await showRemoveDialog(qs.question, id);
                            return null;
                          },
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Icon(Icons.delete),
                                Icon(Icons.delete)
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            onSecondaryTapDown: (details) {
                              HapticFeedback.lightImpact();
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                    details.globalPosition.dx,
                                    details.globalPosition.dy,
                                    screenSize.width -
                                        details.globalPosition.dx,
                                    screenSize.height -
                                        details.globalPosition.dy),
                                items: [
                                  PopupMenuItem(
                                      value: 0,
                                      child: Row(children: [
                                        Icon(Icons.delete,
                                            color: colorScheme.error),
                                        const SizedBox(width: 10),
                                        const Text("削除")
                                      ]),
                                      onTap: () => WidgetsBinding.instance
                                          .addPostFrameCallback((_) =>
                                              showRemoveDialog(
                                                  qs.question, id)))
                                ],
                              );
                            },
                            child: ListTile(
                              title: Text(
                                qs.question,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: LinearProgressIndicator(value: ratio),
                              leading: Icon(Icons.circle,
                                  color: qs.latestCorrect != null
                                      ? (qs.latestCorrect!
                                          ? Colors.green
                                          : Colors.red)
                                      : Colors.grey),
                              onTap: ((() async {
                                final question = await getMiQuestion(id);
                                if (!mounted) return;

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
                                updateQuestion(newMi);
                              })),
                            ),
                          ),
                        );
                      }),
                    )
                  : Center(
                      child: Column(children: [
                      const SizedBox(height: 20),
                      !loading
                          ? dialogLikeMessage(colorScheme, "問題が一つもありません！",
                              "問題を作成するには、右下の+ボタンから作成してください。")
                          : const SizedBox(
                              height: 70,
                              width: 70,
                              child: CircularProgressIndicator(),
                            )
                    ])),
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
                  }).then((value) => updateQuestion(value));
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
                (value) => updateQuestion(value),
              );
            }
          })),
          tooltip: "問題を作成",
          child: const Icon(Icons.add),
        ));
  }

  /// 問題を削除するダイアログを表示する
  Future<void> showRemoveDialog(String title, int id) async {
    setState(() => loading = true);

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$titleを削除しますか？'),
          content: const Text('この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('はい'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('いいえ'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await removeQuestion(id);
      if (!mounted) return;

      setState(() {
        _questionSummaries.remove(id);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除しました')));
    }

    _endLoading();
  }

  /// 学習開始系ボタンが押されたときの動作
  Future<void> doStudy(bool testButton) async {
    // 学習設定を表示
    final sett = await showResponsiveDialog(
        context,
        StudySettingPage(
            studyMode: testButton ? StudyMode.test : StudyMode.study,
            questionsOrSections: _questionSummaries.values.toList()),
        barTitle: "学習設定") as StudySettings?;
    if (sett == null || !mounted) return;

    // 設定内容をもとに学習を開始
    final result =
        await Navigator.of(context).push<Map<int, bool>?>(MaterialPageRoute(
      builder: (context) => SectionStudyPage(
        title: secInfo.title,
        questionIDs: sett.questionIDs,
        testMode: sett.studyMode == StudyMode.test,
      ),
    ));

    await updateRecord(result, sett.studyMode == StudyMode.test);
  }
}
