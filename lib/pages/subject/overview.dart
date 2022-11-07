import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubjectOverview extends StatefulHookConsumerWidget {
  final String title;
  const SubjectOverview({required this.title, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SubjectOverviewState();
}

class _SubjectOverviewState extends ConsumerState<SubjectOverview> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";

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
                                onPressed: (() {
                                  if (_formKey.currentState!.validate()) {
                                    print(_title);
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
                                    _title = value;
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
