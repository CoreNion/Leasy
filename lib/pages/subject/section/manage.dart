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
  late MiQuestion? mi;

  late String fieldQuestion;
  final List<String> fieldChoices = List.filled(4, "");
  late List<TextEditingController> fieldTextEdits = [];
  late int fieldAnswerNum;

  TextFormField _selectField(int number) {
    return TextFormField(
      decoration: InputDecoration(
          labelText: "$number番目の選択肢",
          icon: const Icon(Icons.dashboard),
          hintText: "選択肢に表示される文を入力"),
      controller: fieldTextEdits[number],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "選択肢に表示される文を入力してください";
        } else {
          fieldChoices[number - 1] = value;
          return null;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    mi = widget.miQuestion;

    // フィールドなどを初期化 (新規作成の場合はTextEditには何も入れないnull)
    fieldTextEdits.add(TextEditingController(text: mi?.question));
    for (var i = 0; i < (mi != null ? mi!.choices.length : 4); i++) {
      fieldTextEdits.add(TextEditingController(text: mi?.choices[i]));
    }
    fieldAnswerNum = mi != null ? mi!.answer : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mi != null ? "問題の編集" : "問題を新規作成する"),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: (() => Navigator.of(context).pop()),
            icon: const Icon(Icons.expand_more)),
        actions: [
          IconButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final miQuestion = MiQuestion(
                      id: mi != null
                          ? mi!.id
                          : DateTime.now().millisecondsSinceEpoch,
                      question: fieldQuestion,
                      choices: fieldChoices,
                      answer: fieldAnswerNum);

                  if (mi != null) {
                    await DataBaseHelper.updateMiQuestion(
                        widget.sectionID, mi!.id, miQuestion);

                    Navigator.pop(context, [mi!.id, fieldQuestion]);
                  } else {
                    final id = DateTime.now().millisecondsSinceEpoch;
                    // DBに作成
                    await DataBaseHelper.createQuestion(
                        widget.sectionID, miQuestion);

                    Navigator.pop(context, [id, fieldQuestion]);
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
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "問題文",
                    icon: Icon(Icons.title),
                    hintText: "問題を入力",
                  ),
                  controller: fieldTextEdits[0],
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "問題文を入力してください";
                    } else {
                      fieldQuestion = value;
                      return null;
                    }
                  },
                ),
                _selectField(1),
                _selectField(2),
                _selectField(3),
                _selectField(4),
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
                                  fieldAnswerNum =
                                      picker.getSelectedValues().first;
                                });
                              },
                              backgroundColor:
                                  Theme.of(context).dialogBackgroundColor,
                              textStyle: Theme.of(context).textTheme.headline6,
                              cancelText: "キャンセル",
                              confirmText: "決定")
                          .showModal(context);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(
                      "正解の選択肢: $fieldAnswerNum番",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
