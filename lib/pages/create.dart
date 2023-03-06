import 'package:flutter/material.dart';

import '../db_helper.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({super.key});

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectStatePage();
}

class _CreateSubjectStatePage extends State<CreateSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
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
              Container(
                  color: colorScheme.background,
                  child: Form(
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
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // DBに作成
                                  DataBaseHelper.createSubject(_title);

                                  // タイトルを報告しながら、元のページに戻る
                                  Navigator.pop(context, _title);
                                }
                              },
                              child: const Text("教科を作成",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                            )
                          ],
                        ),
                      )))
            ])));
  }
}
