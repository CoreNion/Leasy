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
  String _sectionTitle = "";

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
                                        widget.title, _sectionTitle);
                                    print(await DataBaseHelper.getSectionTitles(
                                        widget.title));

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
                                    _sectionTitle = value;
                                    return null;
                                  }
                                },
                              ))),
                    )),
                icon: const Icon(Icons.add))
          ],
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(7.0),
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
            const Divider(),
            const Text(
              "セクション数:${1} 単語数:${1}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )
          ]),
        )));
  }
}
