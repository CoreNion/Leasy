import 'dart:ffi';

import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();
  String _createdSectionTitle = "";
  final List<String> _sectionListStr = <String>[];
  final List<int> _sectionListID = <int>[];

  /// 現在のセクションの情報
  late SubjectInfo subInfo;

  @override
  void initState() {
    super.initState();

    subInfo = widget.subInfo;
    // 保存されているセクションをリストに追加
    getSectionIDs(widget.subInfo.id).then((ids) async {
      for (var id in ids) {
        _sectionListID.add(id);
        final title = await sectionIDtoTitle(id);
        setState(() => _sectionListStr.add(title));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subInfo.title),
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
                          onPressed: _sectionListID.isNotEmpty
                              ? () async {
                                  final mis =
                                      await getMiQuestions(_sectionListID);

                                  if (mis.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                '問題が1つも存在しません。テストを行うには、まずは問題を作成してください。')));
                                    return;
                                  }

                                  final record = await Navigator.of(context)
                                      .push<List<bool>>(MaterialPageRoute(
                                    builder: (context) => SectionStudyPage(
                                      miQuestions: mis,
                                      testMode: true,
                                    ),
                                  ));
                                  if (record == null) {
                                    return;
                                  }

                                  final correct =
                                      record.where((correct) => correct).length;
                                  final inCorrect = record
                                      .where((correct) => !correct)
                                      .length;

                                  // 記録を保存
                                  await updateSubjectRecord(
                                      subInfo.id, correct, inCorrect);

                                  setState(() {
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
                "セクション数:${_sectionListID.length}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Divider(),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _sectionListID.length,
                  itemBuilder: ((context, index) => Dismissible(
                      key: Key(_sectionListStr[index]),
                      onDismissed: (direction) async {
                        await removeSection(
                            widget.subInfo.id, _sectionListID[index]);

                        _sectionListID.removeAt(index);

                        setState(() {
                          _sectionListStr.removeAt(index);
                        });

                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('削除しました')));
                      },
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title:
                                    Text('${_sectionListStr[index]}を削除しますか？'),
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
                        } else if (direction == DismissDirection.endToStart) {
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
                                          if (formKey.currentState!
                                              .validate()) {
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
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "セクション名を入力してください";
                                        } else if (value ==
                                            _sectionListStr[index]) {
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
                          if (!(res ?? false)) return null;
                          await renameSectionName(
                              _sectionListID[index], newTitle);

                          setState(() {
                            _sectionListStr[index] = newTitle;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('名前を変更しました')));
                          return false;
                        }
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
                      child: ListTile(
                        title: Text(_sectionListStr[index]),
                        onTap: () async {
                          final secInfo =
                              await getSectionData(_sectionListID[index]);

                          Navigator.push(context,
                              MaterialPageRoute(builder: ((context) {
                            return SectionPage(
                              sectionInfo: secInfo,
                            );
                          })));
                        },
                      )))),
            ]),
          )),
      floatingActionButton: FloatingActionButton(
          onPressed: (() {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                  title: const Text("セクションを作成"),
                  actions: <Widget>[
                    TextButton(
                        onPressed: (() => Navigator.pop(context)),
                        child: const Text("キャンセル")),
                    TextButton(
                        onPressed: (() async {
                          if (_formKey.currentState!.validate()) {
                            final nav = Navigator.of(context);

                            final id = await createSection(
                                widget.subInfo.id, _createdSectionTitle);
                            setState(() {
                              _sectionListID.add(id);
                              _sectionListStr.add(_createdSectionTitle);
                            });
                            nav.pop();

                            // 作成した教科に移動
                            final secInfo = await getSectionData(id);
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
                      key: _formKey,
                      child: TextFormField(
                        decoration: const InputDecoration(
                            labelText: "セクション名",
                            icon: Icon(Icons.book),
                            hintText: "セクション名を入力"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "セクション名を入力してください";
                          } else {
                            _createdSectionTitle = value;
                            return null;
                          }
                        },
                      ))),
            );
          }),
          tooltip: "セクションを作成",
          child: const Icon(Icons.add)),
    );
  }
}
