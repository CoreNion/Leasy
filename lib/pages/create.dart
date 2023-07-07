import 'package:flutter/material.dart';

import '../class/subject.dart';
import '../helper/subject.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({super.key});

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectStatePage();
}

class _CreateSubjectStatePage extends State<CreateSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: const BorderRadius.all(Radius.circular(25))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                title: const Text("教科を新規作成する"),
                automaticallyImplyLeading: false,
                leading: IconButton(
                    onPressed: (() => Navigator.of(context).pop()),
                    icon: const Icon(Icons.expand_more)),
              ),
              Form(
                  key: _formKey,
                  child: Container(
                      margin: const EdgeInsets.all(15),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "教科名",
                                icon: Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "タイトルを入力してください";
                                } else {
                                  _title = value;
                                  return null;
                                }
                              },
                            ),
                            SizedBox.fromSize(size: const Size.fromHeight(40)),
                            FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 55),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _loading = true);

                                          // 教科の作成処理
                                          final id = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          final subInfo = SubjectInfo(
                                              title: _title,
                                              latestCorrect: 0,
                                              latestIncorrect: 0,
                                              id: id);
                                          await createSubject(subInfo);

                                          // 教科情報を報告しながら、元のページに戻る
                                          if (!mounted) return;
                                          Navigator.pop(context, subInfo);
                                        }
                                      },
                                icon: _loading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onSurface,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.add),
                                label: const Text("教科を作成",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17))),
                          ])))
            ])));
  }
}
