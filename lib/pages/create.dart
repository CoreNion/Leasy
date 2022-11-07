import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/db_helper.dart';
import 'package:mimosa/pages/subject/overview.dart';

import 'top.dart';

class CreateSubjectPage extends StatefulHookConsumerWidget {
  const CreateSubjectPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateSubjectStatePage();
}

class _CreateSubjectStatePage extends ConsumerState<CreateSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                    labelText: "教科名",
                    icon: Icon(Icons.title),
                    hintText: "教科名を入力"),
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
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // DBに作成
                        DataBaseHelper.createSubject(_title);

                        // トップの教科リストの更新
                        final refrashList =
                            ref.watch(subjectListWidgetProvider);
                        refrashList.add(TopPage.createSubjectWidget(_title));
                        ref.watch(subjectListWidgetProvider.notifier).state = [
                          ...refrashList
                        ];

                        // 教科ページへ移動
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) =>
                                    SubjectOverview(title: _title))));
                      }
                    },
                    child: const Text("教科を作成"),
                  ))
            ],
          ),
        ));
  }
}