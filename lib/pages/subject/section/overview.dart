import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // 前回間違えた問題のみ学習する
  bool onlyIncorrect = true;

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

  /// Manageの結果からQuestionを更新する関数
  Future<void> updateQuestion(MiQuestion? newQuestion) async {
    setState(() => loading = true);
    // 何らかの変更があった場合のみ更新
    if (newQuestion != null) {
      final id = newQuestion.id;

      if (_questionSummaries.containsKey(id)) {
        // 既存の問題の場合はMiQuestionなどを更新
        await updateMiQuestion(id, newQuestion);
      } else {
        // IDが存在しない場合は作成
        await createQuestion(newQuestion);
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
    }
    setState(() => loading = false);
  }

  // 学習結果から記録を更新する
  Future<void> updateRecord(
      List<MapEntry<int, bool?>>? records, bool isTest) async {
    if (records == null) return;
    setState(() => loading = true);

    final latestStudyMode = isTest ? "test" : "normal";
    // DBに記録を保存
    await updateSectionRecord(secInfo.tableID, latestStudyMode);

    setState(() {
      secInfo = SectionInfo(
          subjectID: secInfo.tableID,
          title: secInfo.title,
          latestStudyMode: latestStudyMode,
          tableID: secInfo.tableID);
    });

    // 正解記録を適切な場所に保存する
    for (var recordEntry in records) {
      final id = recordEntry.key;
      final correct = recordEntry.value;

      await updateQuestionRecord(id, correct!);

      if (!mounted) return;
      setState(() {
        _questionSummaries[id] = MiQuestionSummary(
            id: id,
            question: _questionSummaries[id]!.question,
            totalCorrect: 0,
            totalInCorrect: 0,
            latestCorrect: null);
      });
    }
    setState(() => loading = false);
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
                                // 不正解のみの場合、不正解の問題のみ送る
                                final sendQs = onlyIncorrect
                                    ? _questionSummaries.entries
                                        .where((entry) =>
                                            !(entry.value.latestCorrect ??
                                                false))
                                        .map((entry) => entry.key)
                                        .toList()
                                    : _questionSummaries.keys.toList();
                                if (sendQs.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              '全ての問題が正解しているため、学習モードは実行されません。\nテストを行うか、不正解問題のみ学習をオフにしてください。')));
                                  return;
                                }

                                await updateRecord(
                                    await Navigator.of(context)
                                        .push<List<MapEntry<int, bool?>>?>(
                                            MaterialPageRoute(
                                      builder: (context) => SectionStudyPage(
                                        title: secInfo.title,
                                        questionIDs: sendQs,
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
                          onPressed: _questionSummaries.isNotEmpty
                              ? () async {
                                  updateRecord(
                                      await Navigator.of(context)
                                          .push<List<MapEntry<int, bool?>>?>(
                                              MaterialPageRoute(
                                        builder: (context) => SectionStudyPage(
                                          title: secInfo.title,
                                          questionIDs:
                                              _questionSummaries.keys.toList(),
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
                                await updateQuestion(newMi);
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
  }
}
