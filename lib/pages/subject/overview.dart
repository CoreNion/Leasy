import 'package:flutter/material.dart';

import '../../db_helper.dart';
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
    DataBaseHelper.getSectionIDs(widget.subInfo.title).then((ids) async {
      for (var id in ids) {
        _sectionListID.add(id);
        final title = await DataBaseHelper.sectionIDtoTitle(id);
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
          actions: <Widget>[
            IconButton(
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

                                  final id = await DataBaseHelper.createSection(
                                      widget.subInfo.title,
                                      _createdSectionTitle);
                                  setState(() {
                                    _sectionListID.add(id);
                                    _sectionListStr.add(_createdSectionTitle);
                                  });
                                  nav.pop();
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
                icon: const Icon(Icons.add))
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
                        child: ElevatedButton(
                            onPressed: _sectionListID.isNotEmpty
                                ? () async {
                                    final mis =
                                        await DataBaseHelper.getMiQuestions(
                                            _sectionListID);

                                    if (mis.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
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

                                    final correct = record
                                        .where((correct) => correct)
                                        .length;
                                    final inCorrect = record
                                        .where((correct) => !correct)
                                        .length;

                                    // 記録を保存
                                    await DataBaseHelper.updateSubjectRecord(
                                        subInfo.title, correct, inCorrect);

                                    setState(() {
                                      subInfo = SubjectInfo(
                                          title: subInfo.title,
                                          latestCorrect: correct,
                                          latestIncorrect: inCorrect);
                                    });
                                  }
                                : null,
                            child: const Text("テストを開始する"))),
                    Padding(
                        padding: const EdgeInsets.all(7.0),
                        child: ElevatedButton.icon(
                          label: const Text("教科を削除する"),
                          icon: const Icon(Icons.delete),
                          style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                  colorScheme.errorContainer),
                              textStyle: MaterialStatePropertyAll(TextStyle(
                                  color: colorScheme.onErrorContainer))),
                          onPressed: () async {
                            final confirm = await showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: ((context) {
                                  return AlertDialog(
                                    title: Text(
                                        '"${widget.subInfo.title}"を削除しますか？'),
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

                            if (confirm) {
                              await DataBaseHelper.removeSubject(
                                  widget.subInfo.title);

                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('削除しました')));
                            }
                          },
                        )),
                  ],
                ),
                Text(
                  "セクション数:${_sectionListID.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Divider(),
                ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _sectionListID.length,
                    itemBuilder: ((context, index) => Dismissible(
                        key: Key(_sectionListStr[index]),
                        onDismissed: (direction) async {
                          await DataBaseHelper.removeSection(
                              widget.subInfo.title, _sectionListID[index]);

                          _sectionListID.removeAt(index);

                          setState(() {
                            _sectionListStr.removeAt(index);
                          });

                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('削除しました')));
                        },
                        confirmDismiss: (direction) async {
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
                          title: Text(_sectionListStr[index]),
                          onTap: () async {
                            final secInfo = await DataBaseHelper.getSectionData(
                                _sectionListID[index]);

                            Navigator.push(context,
                                MaterialPageRoute(builder: ((context) {
                              return SectionPage(
                                sectionInfo: secInfo,
                              );
                            })));
                          },
                        )))),
              ]),
            )));
  }
}
