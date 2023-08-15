import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../class/section.dart';
import '../../class/study.dart';
import '../../class/subject.dart';
import '../../helper/section.dart';
import '../../helper/subject.dart';
import '../../widgets/dialog.dart';
import '../../widgets/overview.dart';
import 'section/overview.dart';
import './study.dart';
import 'study_setting.dart';

class SubjectOverview extends StatefulWidget {
  final SubjectInfo subInfo;
  const SubjectOverview({required this.subInfo, super.key});

  @override
  State<SubjectOverview> createState() => _SubjectOverviewState();
}

class _SubjectOverviewState extends State<SubjectOverview> {
  List<SectionInfo> _sectionInfos = [];

  bool loading = true;

  /// 現在のセクションの情報
  late SubjectInfo subInfo;

  @override
  void initState() {
    super.initState();
    subInfo = widget.subInfo;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 保存されているセクションをリストに追加
      _sectionInfos = await getSectionInfos(widget.subInfo.id);
      setState(() => loading = false);
    });
  }

  void _endLoading() {
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subInfo.title),
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
          child: Column(children: <Widget>[
            scoreBoard(colorScheme, true, subInfo.latestCorrect,
                subInfo.latestIncorrect),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: FilledButton(
                        onPressed: _sectionInfos.isNotEmpty
                            ? () async {
                                // 学習設定を表示
                                final sett = await showResponsiveDialog(
                                    context,
                                    StudySettingPage(
                                        studyMode: StudyMode.test,
                                        questionsOrSections: _sectionInfos),
                                    barTitle: "学習設定") as StudySettings?;
                                if (sett == null || !mounted) return;

                                setState(() => loading = true);
                                final record = await Navigator.of(context)
                                    .push<Map<int, bool>>(MaterialPageRoute(
                                  builder: (context) => SectionStudyPage(
                                    questionIDs: sett.questionIDs,
                                    testMode: sett.studyMode == StudyMode.test,
                                  ),
                                ));
                                if (record == null) {
                                  setState(() => loading = false);
                                  return;
                                }

                                // 記録を保存
                                final correct = record.values
                                    .where((entry) => entry)
                                    .length;
                                final inCorrect = record.values
                                    .where((entry) => !(entry))
                                    .length;

                                // UI更新
                                setState(() {
                                  subInfo = SubjectInfo(
                                      title: subInfo.title,
                                      id: subInfo.id,
                                      latestCorrect: correct,
                                      latestIncorrect: inCorrect);
                                });

                                // 記録を保存
                                updateSubjectRecord(
                                        subInfo.id, correct, inCorrect)
                                    .then((value) {
                                  if (!mounted) return;
                                  setState(() => loading = false);
                                });
                              }
                            : null,
                        child: const Text("テストを開始する"))),
              ],
            ),
            Text(
              "セクション数:${_sectionInfos.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(),
            _sectionInfos.isNotEmpty
                ? ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _sectionInfos.length,
                    itemBuilder: ((context, index) {
                      // セクションID
                      final id = _sectionInfos[index].tableID;

                      // セクションの完了率
                      double? ratio = _sectionInfos[index].completionRate;
                      if (ratio != null && ratio.isNaN) ratio = null;

                      // セクションのタイトル
                      final title = _sectionInfos[index].title;
                      // リスト用のタイトル (完了率を含む)
                      final exTitle =
                          "$title (${ratio != null ? '${(ratio * 100).ceil()}%完了' : '問題未作成'})";

                      return Dismissible(
                        key: Key(id.toString()),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            await showRemoveDialog(title, index);
                          } else if (direction == DismissDirection.endToStart) {
                            await showRenameDialog(title, index);
                          }
                          return null;
                        },
                        background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.delete))),
                        secondaryBackground: Container(
                            color: Colors.blue,
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: const Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.title))),
                        child: GestureDetector(
                          onSecondaryTapDown: (details) {
                            HapticFeedback.lightImpact();
                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                  screenSize.width - details.globalPosition.dx,
                                  screenSize.height -
                                      details.globalPosition.dy),
                              items: [
                                PopupMenuItem(
                                    value: 1,
                                    child: Row(children: [
                                      Icon(Icons.title,
                                          color: colorScheme.primary),
                                      const SizedBox(width: 10),
                                      const Text("名前を変更")
                                    ]),
                                    onTap: () => WidgetsBinding.instance
                                        .addPostFrameCallback((_) =>
                                            showRenameDialog(title, index))),
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
                                            showRemoveDialog(title, index)))
                              ],
                            );
                          },
                          child: ListTile(
                            title: Text(exTitle),
                            subtitle:
                                LinearProgressIndicator(value: ratio ?? 0),
                            onTap: () async {
                              final secInfo = await getSectionData(id);
                              if (!mounted) return;

                              Navigator.push(context,
                                  MaterialPageRoute(builder: ((context) {
                                return SectionPage(
                                  sectionInfo: secInfo,
                                );
                              })));
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
                  ]))
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (() {
          showDialog(
            context: context,
            builder: (context) {
              final formKey = GlobalKey<FormState>();
              late String createdSectionTitle;

              return AlertDialog(
                  title: const Text("セクションを作成"),
                  actions: <Widget>[
                    TextButton(
                        onPressed: (() => Navigator.pop(context)),
                        child: const Text("キャンセル")),
                    TextButton(
                        onPressed: (() async {
                          if (formKey.currentState!.validate()) {
                            final id = DateTime.now().millisecondsSinceEpoch;
                            final secInfo = SectionInfo(
                                tableID: id,
                                latestStudyMode: "none",
                                title: createdSectionTitle,
                                subjectID: widget.subInfo.id);
                            await createSection(secInfo);
                            if (!mounted) return;

                            // セクション一覧に追加
                            setState(() {
                              _sectionInfos.add(secInfo);
                            });
                            Navigator.pop(context);

                            // 作成した教科に移動
                            Navigator.push(context,
                                MaterialPageRoute(builder: ((context) {
                              return SectionPage(
                                sectionInfo: secInfo,
                              );
                            })));
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
        }),
        tooltip: "セクションを作成",
        child: const Icon(Icons.add),
      ),
    );
  }

  /// セクション名を変更するダイアログを表示する
  Future<void> showRenameDialog(String oldTitle, int index) async {
    final formKey = GlobalKey<FormState>();
    late String newTitle;

    setState(() => loading = true);

    final res = await showDialog<bool?>(
        context: context,
        builder: (builder) {
          return AlertDialog(
            title: const Text("新しい名前を入力"),
            actions: [
              TextButton(
                  onPressed: (() => Navigator.pop(context, false)),
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
                    labelText: "セクション名",
                    icon: Icon(Icons.book),
                    hintText: "セクション名を入力"),
                initialValue: oldTitle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "セクション名を入力してください";
                  } else if (value == oldTitle) {
                    return "新しいセクション名を入力してください";
                  } else {
                    newTitle = value;
                    return null;
                  }
                },
              ),
            ),
          );
        });
    if (!(res ?? false)) {
      _endLoading();
      return;
    }

    // 更新を適用
    setState(() {
      _sectionInfos[index] = _sectionInfos[index].copyWith(
        title: newTitle,
      );
    });

    // DB上の名前を変更
    renameSectionName(_sectionInfos[index].tableID, newTitle).then((value) {
      _endLoading();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名前を変更しました')));
    });
    return;
  }

  Future<void> showRemoveDialog(String title, int index) async {
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
      _endLoading();
      return;
    }

    removeSection(widget.subInfo.id, _sectionInfos[index].tableID)
        .then((value) {
      _endLoading();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除しました')));
    });

    setState(() {
      _sectionInfos.removeAt(index);
    });
    return;
  }
}
