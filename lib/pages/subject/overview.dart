import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/db_helper.dart';

class SubjectOverview extends StatefulHookConsumerWidget {
  final String title;
  const SubjectOverview({required this.title, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SubjectOverviewState();
}

class _SubjectOverviewState extends ConsumerState<SubjectOverview> {
  final _formKey = GlobalKey<FormState>();
  String _createdSectionTitle = "";
  final List<String> _sectionListStr = <String>[];
  final List<int> _sectionListID = <int>[];

  @override
  void initState() {
    super.initState();

    // 保存されているセクションをリストに追加
    DataBaseHelper.getSectionIDs(widget.title).then((ids) async {
      for (var id in ids) {
        _sectionListID.add(id);
        final title = await DataBaseHelper.sectionIDtoTitle(id);
        setState(() => _sectionListStr.add(title));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
                onPressed: (() => showDialog(
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
                                    await DataBaseHelper.createSection(
                                        widget.title, _createdSectionTitle);
                                    setState(() {
                                      _sectionListStr.add(_createdSectionTitle);
                                    });

                                    Navigator.pop(context);
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
                    )),
                icon: const Icon(Icons.add))
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.all(7.0),
            child: SingleChildScrollView(
              child: Column(children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Padding(
                        padding: EdgeInsets.all(7.0),
                        child: ElevatedButton(
                          onPressed: null,
                          child: Text("続きから学習を開始する"),
                        )),
                    Padding(
                        padding: EdgeInsets.all(7.0),
                        child: ElevatedButton(
                            onPressed: null, child: Text("テストを開始する"))),
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
                              widget.title, _sectionListID[index]);

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
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('はい'),
                                  ),
                                  SimpleDialogOption(
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
                        )))),
              ]),
            )));
  }
}
