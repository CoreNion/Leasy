import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../db_helper.dart';

class SectionManagePage extends StatefulHookConsumerWidget {
  final int sectionID;
  final MiQuestion? miQuestion;

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
  late int answerNum;

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
    answerNum = widget.miQuestion != null ? widget.miQuestion!.answer : 1;

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
                    final miQuestion = MiQuestion(
                        id: widget.miQuestion != null
                            ? widget.miQuestion!.id
                            : DateTime.now().millisecondsSinceEpoch,
                        question: question,
                        choice1: choices[0],
                        choice2: choices[1],
                        choice3: choices[2],
                        choice4: choices[3],
                        answer: answerNum);

                    if (widget.miQuestion != null) {
                      await DataBaseHelper.updateMiQuestion(
                          widget.sectionID, widget.miQuestion!.id, miQuestion);

                      Navigator.pop(context, [widget.miQuestion!.id, question]);
                    } else {
                      final id = DateTime.now().millisecondsSinceEpoch;
                      // DBに作成
                      await DataBaseHelper.createQuestion(
                          widget.sectionID, miQuestion);

                      Navigator.pop(context, [id, question]);
                    }
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
                  selectField(4, widget.miQuestion?.choice4),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      onPressed: () {
                        Picker(
                                adapter: NumberPickerAdapter(data: [
                                  const NumberPickerColumn(begin: 1, end: 4),
                                ]),
                                changeToFirst: true,
                                onConfirm: (Picker picker, List value) {
                                  setState(() {
                                    answerNum =
                                        picker.getSelectedValues().first;
                                  });
                                },
                                backgroundColor:
                                    Theme.of(context).dialogBackgroundColor,
                                textStyle:
                                    Theme.of(context).textTheme.headline6,
                                cancelText: "キャンセル",
                                confirmText: "決定")
                            .showModal(context);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(
                        "正解の選択肢: $answerNum番",
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  )
                ],
              ),
            )));
  }
}
