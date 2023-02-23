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
    return SingleChildScrollView(
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
              Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(7.0),
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
                        Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 5),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  fixedSize: const Size(150, 40)),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // DBに作成
                                  DataBaseHelper.createSubject(_title);

                                  // タイトルを報告しながら、元のページに戻る
                                  Navigator.pop(context, _title);
                                }
                              },
                              child: const Text("教科を作成"),
                            ))
                      ],
                    ),
                  ))
            ])));
  }
}
