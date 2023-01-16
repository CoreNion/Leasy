import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../db_helper.dart';

class SectionManagePage extends StatefulHookConsumerWidget {
  final int sectionID;
  final MiQuestionModel? miQuestion;

  const SectionManagePage(
      {super.key, required this.sectionID, this.miQuestion});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SectionManagePageState();
}

class _SectionManagePageState extends ConsumerState<SectionManagePage> {
  final _formKey = GlobalKey<FormState>();
  late String question;
  final List<String> choices = List.filled(4, "");

  TextFormField selectField(int number, String? text) {
    return TextFormField(
      decoration: InputDecoration(
          labelText: "$number番目の選択肢",
          icon: const Icon(Icons.dashboard),
          hintText: "選択肢に表示される文を入力"),
      controller: TextEditingController(text: text),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "選択肢に表示される文を入力してください";
        } else {
          choices[number - 1] = value;
          return null;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.miQuestion != null ? "問題の編集" : "問題を新規作成する"),
          automaticallyImplyLeading: false,
          leading: IconButton(
              onPressed: (() => Navigator.of(context).pop()),
              icon: const Icon(Icons.expand_more)),
          actions: [
            IconButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // DBに作成
                    await DataBaseHelper.createQuestion(
                        widget.sectionID,
                        MiQuestionModel(
                            id: DateTime.now().millisecondsSinceEpoch,
                            question: question,
                            choice1: choices[0],
                            choice2: choices[1],
                            choice3: choices[2],
                            choice4: choices[3]));

                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.save))
          ],
        ),
        body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(7.0),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "問題文",
                      icon: Icon(Icons.title),
                      hintText: "問題を入力",
                    ),
                    controller: TextEditingController(
                        text: widget.miQuestion != null
                            ? widget.miQuestion!.question
                            : null),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "問題文を入力してください";
                      } else {
                        question = value;
                        return null;
                      }
                    },
                  ),
                  selectField(1, widget.miQuestion?.choice1),
                  selectField(2, widget.miQuestion?.choice2),
                  selectField(3, widget.miQuestion?.choice3),
                  selectField(4, widget.miQuestion?.choice4)
                ],
              ),
            )));
  }
}
