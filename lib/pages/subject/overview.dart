import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../class/subject.dart';
import '../../helper/question.dart';
import '../../helper/section.dart';
import '../../helper/subject.dart';
import '../../widgets/overview.dart';
import 'section/overview.dart';
import './study.dart';

class SubjectOverview extends StatefulWidget {
  final SubjectInfo subInfo;
  const SubjectOverview({required this.subInfo, super.key});

  @override
  State<SubjectOverview> createState() => _SubjectOverviewState();
}

class _SubjectOverviewState extends State<SubjectOverview> {
  late Map<int, String> _sectionSummaries = {};

  bool loading = true;

  /// 現在のセクションの情報
  late SubjectInfo subInfo;

  @override
  void initState() {
    super.initState();
    subInfo = widget.subInfo;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 保存されているセクションをリストに追加
      _sectionSummaries = await getSectionSummaries(widget.subInfo.id);
      setState(() => loading = false);
    });
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
                          onPressed: _sectionSummaries.isNotEmpty
                              ? () async {
                                  setState(() => loading = true);

                                  final qIDs = await getMiQuestionsID(
                                      _sectionSummaries.keys.toList());
                                  if (!mounted) return;

                                  if (qIDs.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                '問題が1つも存在しません。テストを行うには、まずは問題を作成してください。')));
                                    setState(() => loading = false);
                                    return;
                                  }

                                  final record = await Navigator.of(context)
                                      .push<List<MapEntry<int, bool?>>?>(
                                          MaterialPageRoute(
                                    builder: (context) => SectionStudyPage(
                                      questionIDs: qIDs,
                                      testMode: true,
                                    ),
                                  ));
                                  if (record == null) {
                                    setState(() => loading = false);
                                    return;
                                  }

                                  final correct = record
                                      .where((entry) => entry.value!)
                                      .length;
                                  final inCorrect = record
                                      .where((entry) => !(entry.value!))
                                      .length;

                                  // 記録を保存
                                  await updateSubjectRecord(
                                      subInfo.id, correct, inCorrect);

                                  if (!mounted) return;
                                  setState(() {
                                    loading = false;
                                    subInfo = SubjectInfo(
                                        title: subInfo.title,
                                        id: subInfo.id,
                                        latestCorrect: correct,
                                        latestIncorrect: inCorrect);
                                  });
                                }
                              : null,
                          child: const Text("テストを開始する"))),
                ],
              ),
              Text(
                "セクション数:${_sectionSummaries.length}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Divider(),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _sectionSummaries.length,
                  itemBuilder: ((context, index) {
                    final id = _sectionSummaries.keys.elementAt(index);
                    final title = _sectionSummaries.values.elementAt(index);

                    return Dismissible(
                      key: Key(id.toString()),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await showRemoveDialog(title, id);
                        } else if (direction == DismissDirection.endToStart) {
                          await showRenameDialog(title, id);
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
                                screenSize.height - details.globalPosition.dy),
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
                                      .addPostFrameCallback(
                                          (_) => showRenameDialog(title, id))),
                              PopupMenuItem(
                                  value: 0,
                                  child: Row(children: [
                                    Icon(Icons.delete,
                                        color: colorScheme.error),
                                    const SizedBox(width: 10),
                                    const Text("削除")
                                  ]),
                                  onTap: () => WidgetsBinding.instance
                                      .addPostFrameCallback(
                                          (_) => showRemoveDialog(title, id)))
                            ],
                          );
                        },
                        child: ListTile(
                          title: Text(title),
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
                  })),
            ]),
          )),
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
                            final section = await createSection(
                                widget.subInfo.id, createdSectionTitle);
                            if (!mounted) return;

                            setState(() {
                              _sectionSummaries
                                  .addAll({section.tableID: section.title});
                            });
                            Navigator.pop(context);

                            // 作成した教科に移動
                            Navigator.push(context,
                                MaterialPageRoute(builder: ((context) {
                              return SectionPage(
                                sectionInfo: section,
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
  Future<void> showRenameDialog(String oldTitle, int id) async {
    final formKey = GlobalKey<FormState>();
    late String newTitle;

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
    if (!(res ?? false)) return;

    // DB上の名前を変更
    await renameSectionName(id, newTitle);
    if (!mounted) return;

    // リスト上の名前を変更
    setState(() {
      _sectionSummaries[id] = newTitle;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('名前を変更しました')));
    return;
  }

  Future<void> showRemoveDialog(String title, int id) async {
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
    if (!(res ?? false)) return;

    await removeSection(widget.subInfo.id, id);
    if (!mounted) return;

    setState(() {
      _sectionSummaries.remove(id);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('削除しました')));
    return;
  }
}
