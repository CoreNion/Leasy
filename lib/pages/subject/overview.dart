import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mimosa/utility.dart';

import '../../class/overview.dart';
import '../../class/question.dart';
import '../../class/section.dart';
import '../../class/study.dart';
import '../../class/subject.dart';
import '../../helper/question.dart';
import '../../helper/section.dart';
import '../../helper/subject.dart';
import '../../widgets/dialog.dart';
import '../../widgets/overview.dart';
import 'section/manage.dart';
import './study.dart';
import 'study_setting.dart';

/// 教科・セクションの概要ページ
class SubSecOverview<T> extends StatefulWidget {
  // 教科またはセクションの情報
  final T info;

  /// 教科の概要ページ
  const SubSecOverview({required this.info, super.key});

  @override
  State<SubSecOverview> createState() => _SubSecOverviewState();
}

class _SubSecOverviewState extends State<SubSecOverview> {
  /// 表示するべき概要の種類
  late OverviewType type;

  /// 教科の情報
  late SubjectInfo subInfo;

  /// セクション情報
  late SectionInfo secInfo;

  /// 一覧の種類の文字列
  late String listTypeStr;

  /// 前回学習での正答数
  int latestCorrect = 0;

  /// 前回学習での不正解数
  int latestIncorrect = 0;

  /// 一覧のlength
  int listLength = 0;

  /// セクション一覧
  List<SectionInfo> sectionInfos = [];

  /// 問題概要一覧
  List<MiQuestionSummary> questionSummaries = [];

  /// 教科/セクションの完了率
  double _completionRate = 0;

  bool loading = true;
  late ColorScheme colorScheme;
  late Size screenSize;

  @override
  void initState() {
    super.initState();

    // 表示するべき情報を判別
    if (widget.info is SubjectInfo) {
      setState(() {
        type = OverviewType.subject;
        subInfo = widget.info;
        listTypeStr = "セクション";

        latestCorrect = subInfo.latestCorrect;
        latestIncorrect = subInfo.latestIncorrect;
      });
    } else if (widget.info is SectionInfo) {
      setState(() {
        type = OverviewType.section;
        secInfo = widget.info;
        listTypeStr = "問題";

        _completionRate = secInfo.completionRate ?? 0;
      });
    } else {
      throw ArgumentError("SubjectInfo/SectionInfo以外の型が渡されました");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (type == OverviewType.subject) {
        // 保存されているセクションをリストに追加
        sectionInfos = await getSectionInfos(widget.info.id);
        // 教科の完了率を計算
        _completionRate = (await calcSubjectCompletionRate(widget.info.id));

        /// リストの長さを反映
        listLength = sectionInfos.length;
      } else {
        // 保存されている問題をリストに追加
        questionSummaries = await getMiQuestionSummaries(secInfo.tableID);

        /// いくつかの値を反映
        listLength = questionSummaries.length;
        latestCorrect =
            questionSummaries.where((qs) => qs.latestCorrect ?? false).length;
        latestIncorrect = questionSummaries
            .where((qs) => !(qs.latestCorrect ?? false))
            .length;
      }

      if (!mounted) return;
      setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    colorScheme = Theme.of(context).colorScheme;
    screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(checkLargeSC(context)
            ? "${type.toString()}の概要"
            : widget.info.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            height: 20,
            width: 20,
            child: loading ? const CircularProgressIndicator() : null,
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(7.0),
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: checkLargeSC(context)
                ? Container(
                    margin: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: 6,
                            child: Column(children: [
                              Container(
                                margin: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(widget.info.title,
                                        style: const TextStyle(
                                          fontSize: 35,
                                        )),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                            "${(_completionRate.isNaN ? 0 : _completionRate * 100).floor()}%完了",
                                            style:
                                                const TextStyle(fontSize: 17)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: SizedBox(
                                              height: 13,
                                              child: LinearProgressIndicator(
                                                  value: _completionRate.isNaN
                                                      ? 0
                                                      : _completionRate),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: colorScheme.background,
                                      border: Border.all(
                                          color: colorScheme.outline),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                  child: Column(children: [
                                    // タイトルと作成ボタン(横並び)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              "$listTypeStr一覧",
                                              style: const TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        IconButton.filled(
                                          onPressed: createTask,
                                          icon: const Icon(Icons.add),
                                          tooltip: "$listTypeStrを作成",
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    listCard(),
                                  ]))
                            ]),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(children: [
                              scoreBoard(colorScheme, true, latestCorrect,
                                  latestIncorrect),
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: colorScheme.background,
                                    border:
                                        Border.all(color: colorScheme.outline),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                                child: Column(
                                  children: [
                                    Text("${type.toString()}全体での学習を始める",
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold)),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    sectionInfos.isNotEmpty ||
                                            questionSummaries.isNotEmpty
                                        ? StudySettingPage(
                                            studyMode: StudyMode.study,
                                            questionsOrSections:
                                                type == OverviewType.subject
                                                    ? sectionInfos
                                                    : questionSummaries,
                                            endToDo: doStudy,
                                          )
                                        : const LinearProgressIndicator()
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ],
                      )
                    ]))
                : Column(
                    children: <Widget>[
                      scoreBoard(
                          colorScheme, true, latestCorrect, latestIncorrect),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                              padding: const EdgeInsets.all(7.0),
                              child: FilledButton(
                                  onPressed: () => sectionInfos.isNotEmpty ||
                                          questionSummaries.isNotEmpty
                                      ? onStudyButtonPressed(StudyMode.study)
                                      : null,
                                  child: const Text("学習開始"))),
                          Padding(
                              padding: const EdgeInsets.all(7.0),
                              child: ElevatedButton(
                                  onPressed: () => sectionInfos.isNotEmpty ||
                                          questionSummaries.isNotEmpty
                                      ? onStudyButtonPressed(StudyMode.test)
                                      : null,
                                  child: const Text("テスト開始"))),
                        ],
                      ),
                      const Divider(),
                      listCard(),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createTask,
        tooltip: "$listTypeStrを作成",
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 一覧リスト
  Widget listCard() {
    return sectionInfos.isNotEmpty || questionSummaries.isNotEmpty
        ? ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: listLength,
            itemBuilder: ((context, index) {
              // ID
              late int id;
              // 完了率
              double? ratio;
              // タイトル
              late String title;
              // リスト用のタイトル (完了/正答率を含む)
              late String exTitle;
              // 前回正解/不正解表示のリーディング (問題のみ)
              Widget? leading;

              if (type == OverviewType.subject) {
                final secInfo = sectionInfos[index];

                // セクションのID
                id = secInfo.tableID;
                // セクションの完了率
                ratio = secInfo.completionRate;
                if (ratio != null && ratio.isNaN) ratio = null;

                // セクションのタイトル
                title = secInfo.title;
                // リスト用のタイトル (セクションの完了率を含む)
                exTitle =
                    "$title (${ratio != null ? '${(ratio * 100).ceil()}%完了' : '問題未作成'})";
              } else {
                final qs = questionSummaries[index];

                // 問題のID
                id = qs.id;

                // 問題の正答率
                ratio = qs.totalCorrect == 0
                    ? 0.toDouble()
                    : qs.totalCorrect / (qs.totalCorrect + qs.totalInCorrect);

                // 問題のタイトル
                title = qs.question;
                // リスト用のタイトル (問題の完了率を含む)
                exTitle = "$title [回答率${(ratio * 100).ceil()}%]";
                // 前回正解/不正解表示のリーディング
                leading = Icon(Icons.circle,
                    color: qs.latestCorrect != null
                        ? (qs.latestCorrect! ? Colors.green : Colors.red)
                        : Colors.grey);
              }

              return Dismissible(
                key: Key(id.toString()),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await removeTask(title, index);
                  } else if (direction == DismissDirection.endToStart) {
                    type == OverviewType.subject
                        ? await editSection(index)
                        : await removeTask(title, index);
                  }
                  return null;
                },
                background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.delete))),
                secondaryBackground: type == OverviewType.subject
                    ? Container(
                        color: Colors.blue,
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.title)))
                    : null,
                child: GestureDetector(
                  onSecondaryTapDown: (details) {
                    HapticFeedback.lightImpact();
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          screenSize.width - details.globalPosition.dx,
                          screenSize.height - details.globalPosition.dy),
                      items: [
                        PopupMenuItem(
                            value: 1,
                            child: Row(children: [
                              Icon(Icons.title, color: colorScheme.primary),
                              const SizedBox(width: 10),
                              Text(type == OverviewType.subject
                                  ? "名前を変更"
                                  : "問題を編集")
                            ]),
                            onTap: () => WidgetsBinding.instance
                                .addPostFrameCallback((_) =>
                                    type == OverviewType.subject
                                        ? editSection(index)
                                        : editQuestion(id, index))),
                        PopupMenuItem(
                            value: 0,
                            child: Row(children: [
                              Icon(Icons.delete, color: colorScheme.error),
                              const SizedBox(width: 10),
                              const Text("削除")
                            ]),
                            onTap: () => WidgetsBinding.instance
                                .addPostFrameCallback(
                                    (_) => removeTask(title, index)))
                      ],
                    );
                  },
                  child: ListTile(
                    title: Text(exTitle),
                    subtitle: LinearProgressIndicator(value: ratio ?? 0),
                    leading: leading,
                    onTap: () async {
                      if (type == OverviewType.subject) {
                        // セクションの概要ページに移動
                        Navigator.push(context,
                            MaterialPageRoute(builder: ((context) {
                          return SubSecOverview(
                            info: sectionInfos[index],
                          );
                        })));
                      } else {
                        // 問題概要ページを表示
                        await editQuestion(id, index);
                      }
                      if (!mounted) return;
                    },
                  ),
                ),
              );
            }))
        : Center(
            child: Column(children: [
            const SizedBox(height: 20),
            !loading
                ? dialogLikeMessage(colorScheme, "セクションが一つもありません！",
                    "Leasyでは、問題(覚えたい単語類など)を、セクションを通してジャンルや範囲別などに分類できるように設計されています。\n右下の+ボタンからセクションを作成してください。")
                : const SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(),
                  ),
          ]));
  }

  /// 学習系ボタンが押された時の動作 (小画面時用)
  Future<void> onStudyButtonPressed(StudyMode mode) async {
    // 学習設定を表示
    final sett = await showResponsiveDialog(
        context,
        StudySettingPage(
          studyMode: mode,
          questionsOrSections:
              type == OverviewType.subject ? sectionInfos : questionSummaries,
        ),
        barTitle: "学習設定");
    if (sett == null || !mounted) {
      return;
    }

    await doStudy(sett);
  }

  /// 学習を開始する動作
  Future<void> doStudy(StudySettings settings) async {
    setState(() => loading = true);

    // 学習を開始し、記録を取得
    final records =
        await Navigator.of(context).push<Map<int, bool>>(MaterialPageRoute(
      builder: (context) => SectionStudyPage(
        questionIDs: settings.questionIDs,
        testMode: settings.studyMode == StudyMode.test,
        title: settings.studyMode.toString(),
      ),
    ));
    if (records == null) {
      setState(() => loading = false);
      return;
    }
    endLoading();

    // 正答数と不正解数を反映
    latestCorrect = records.values.where((entry) => entry).length;
    latestIncorrect = records.values.where((entry) => !(entry)).length;
    // 完了率を計算
    _completionRate = latestCorrect / (latestCorrect + latestIncorrect);

    if (type == OverviewType.subject) {
      // 教科情報を更新
      setState(() {
        subInfo = SubjectInfo(
            title: subInfo.title,
            id: subInfo.id,
            latestCorrect: latestCorrect,
            latestIncorrect: latestCorrect);
      });

      // 記録を保存
      updateSubjectRecord(subInfo.id, latestCorrect, latestIncorrect).then(
        (value) {
          if (!mounted) return;
          setState(() => loading = false);
        },
      );
    } else {
      // セクション情報を更新
      final latestStudyMode =
          settings.studyMode == StudyMode.test ? "test" : "normal";
      setState(() {
        secInfo = SectionInfo(
            tableID: secInfo.tableID,
            latestStudyMode: latestStudyMode,
            title: secInfo.title,
            subjectID: secInfo.subjectID,
            completionRate: secInfo.completionRate);
      });

      // UI上の各問題の記録を更新
      for (var record in records.entries) {
        final id = record.key;
        final correct = record.value;

        final qs = questionSummaries.firstWhere((qs) => qs.id == id);
        final newQs = MiQuestionSummary(
            id: id,
            question: qs.question,
            totalCorrect: qs.totalCorrect + (correct ? 1 : 0),
            totalInCorrect: qs.totalInCorrect + (correct ? 0 : 1),
            latestCorrect: correct);

        setState(() {
          questionSummaries[questionSummaries.indexOf(qs)] = newQs;
        });
      }

      // DBにセクションの記録を保存
      final secTask = updateSectionRecord(secInfo.tableID, latestStudyMode);
      // DBの各問題の記録を更新
      final queTask = updateQuestionRecords(records);
      // 裏で実行
      Future.wait([secTask, queTask]).then((value) {
        if (!mounted) return;
        endLoading();
      });
    }
  }

  /// セクション・問題を作成する
  Future<void> createTask() async {
    if (type == OverviewType.subject) {
      await editSection(null);
    } else {
      await editQuestion(null, null);
    }
  }

  /// セクションを編集/作成する
  Future<void> editSection(int? index) async {
    return showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        late String createdSectionTitle;

        return AlertDialog(
            title: Text(index != null ? "新しい名前を入力" : "セクションを作成"),
            actions: <Widget>[
              TextButton(
                  onPressed: (() => Navigator.pop(context)),
                  child: const Text("キャンセル")),
              TextButton(
                  onPressed: (() async {
                    if (formKey.currentState!.validate()) {
                      if (index != null) {
                        // 更新を適用
                        setState(() {
                          sectionInfos[index] = sectionInfos[index].copyWith(
                            title: createdSectionTitle,
                          );
                        });

                        // DB上の名前を変更
                        renameSectionName(sectionInfos[index].tableID,
                                createdSectionTitle)
                            .then(
                          (value) {
                            endLoading();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('名前を変更しました')));
                          },
                        );

                        // 作成した教科に移動
                        Navigator.pop(context);
                      } else {
                        // セクションを新規作成
                        final id = DateTime.now().millisecondsSinceEpoch;
                        final secInfo = SectionInfo(
                            tableID: id,
                            latestStudyMode: "none",
                            title: createdSectionTitle,
                            subjectID: widget.info.id);
                        await createSection(secInfo);
                        if (!mounted) return;

                        // セクション一覧に追加
                        sectionInfos.add(secInfo);
                        updateLength();

                        // 作成したセクションに移動
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: ((context) {
                          return SubSecOverview(
                            info: secInfo,
                          );
                        })));
                      }
                    }
                  }),
                  child: const Text("決定")),
            ],
            content: Form(
                key: formKey,
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: "セクション名",
                      icon: Icon(Icons.book),
                      hintText: "セクション名を入力"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "セクション名を入力してください";
                    } else {
                      createdSectionTitle = value;
                      return null;
                    }
                  },
                )));
      },
    );
  }

  /// 問題を編集/作成する
  Future<void> editQuestion(int? qID, int? index) async {
    final question = qID != null ? await getMiQuestion(qID) : null;
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
    if (newMi == null) return;
    startLoading();

    if (qID == null) {
      // 問題一覧に追加
      questionSummaries.add(MiQuestionSummary(
          id: newMi.id,
          question: newMi.question,
          totalCorrect: 0,
          totalInCorrect: 0,
          latestCorrect: null));
      // DB新規作成
      createQuestion(newMi).then((value) {
        endLoading();
      });
    } else {
      // 問題一覧を更新
      questionSummaries[index!] = MiQuestionSummary(
          id: newMi.id,
          question: newMi.question,
          totalCorrect: newMi.totalCorrect,
          totalInCorrect: newMi.totalInCorrect,
          latestCorrect: newMi.latestCorrect);
      // DB更新
      updateMiQuestion(newMi.id, newMi).then((value) {
        endLoading();
      });
    }

    updateLength();
  }

  /// セクション・問題を削除する
  Future<void> removeTask(String title, int index) async {
    setState(() => loading = true);
    final res = await showDialog<bool?>(
        context: context,
        builder: (builder) {
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
        });
    if (!(res ?? false)) {
      endLoading();
      return;
    }

    final removeTask = type == OverviewType.subject
        ? removeSection(subInfo.id, sectionInfos[index].tableID)
        : removeQuestion(questionSummaries[index].id);
    removeTask.then((value) {
      endLoading();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除しました')));
    });

    type == OverviewType.subject
        ? sectionInfos.removeAt(index)
        : questionSummaries.removeAt(index);
    updateLength();

    return;
  }

  /// sectionInfosやquestionSummariesの新規作成要素をUIに反映させる
  void updateLength() {
    setState(() {
      listLength = type == OverviewType.subject
          ? sectionInfos.length
          : questionSummaries.length;
    });
  }

  /// ローディングUIを開始する
  void startLoading() {
    setState(() {
      loading = true;
    });
  }

  /// ローディングUIを終了する
  void endLoading() {
    setState(() {
      loading = false;
    });
  }
}
