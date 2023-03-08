import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';

import '../../../class/question.dart';
import '../../../helper/question.dart';

class SectionManagePage extends StatefulWidget {
  final int sectionID;
  final MiQuestion? miQuestion;

  const SectionManagePage(
      {super.key, required this.sectionID, this.miQuestion});

  @override
  State<SectionManagePage> createState() => _SectionManagePageState();
}

class _SectionManagePageState extends State<SectionManagePage> {
  final _formKey = GlobalKey<FormState>();
  late MiQuestion? mi;

  /// フォームが初期値から変化されたか
  bool formChanged = false;
  late List<bool> selectedInputType;
  late String fieldQuestion;
  final List<String> fieldChoices = List.filled(4, "");
  late List<TextEditingController> fieldTextEdits = [];
  late int fieldAnswerNum;

  final shape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  );

  TextFormField _selectField(int number) {
    return TextFormField(
      onChanged: (value) {
        formChanged = true;
      },
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

  /// 保存しないで終了しても良いか尋ねる関数
  Future<bool> _confirmExit(context) async {
    // フォームに変化があった時のみ尋ねる
    if (formChanged) {
      final res = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("確認"),
              content: const Text("変更を保存しないで終了しますか？"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("いいえ")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("はい")),
              ],
            );
          });
      if (res != null) {
        return res;
      } else {
        return false;
      }
    } else {
      return true;
    }
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
    if (mi != null) {
      fieldAnswerNum = mi!.answer;
      selectedInputType = (mi!.isInput ? [false, true] : [true, false]);
    } else {
      fieldAnswerNum = 1;
      selectedInputType = [true, false];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
        onWillPop: () {
          return _confirmExit(context);
        },
        child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text(mi != null ? "問題の編集" : "問題を新規作成する"),
                      shape: shape,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                          onPressed: (() async {
                            if (await _confirmExit(context)) {
                              Navigator.of(context).pop();
                            }
                          }),
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
                                    answer: fieldAnswerNum,
                                    isInput: selectedInputType[1]);

                                if (mi != null) {
                                  await updateMiQuestion(
                                      widget.sectionID, mi!.id, miQuestion);

                                  Navigator.pop(context, [mi!.id, miQuestion]);
                                } else {
                                  final id =
                                      DateTime.now().millisecondsSinceEpoch;
                                  // DBに作成
                                  await createQuestion(
                                      widget.sectionID, miQuestion);

                                  Navigator.pop(context, [id, miQuestion]);
                                }
                              }
                            },
                            icon: const Icon(Icons.save))
                      ],
                    ),
                    Container(
                      color: colorScheme.background,
                      padding: const EdgeInsets.all(7.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            ToggleButtons(
                              onPressed: (int index) {
                                formChanged = true;

                                setState(() {
                                  for (int i = 0;
                                      i < selectedInputType.length;
                                      i++) {
                                    selectedInputType[i] = i == index;
                                  }
                                });
                              },
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              constraints: const BoxConstraints(
                                minHeight: 40.0,
                                minWidth: 100.0,
                              ),
                              isSelected: selectedInputType,
                              children: const <Widget>[
                                Text(
                                  "4択問題",
                                  style: TextStyle(fontSize: 17),
                                ),
                                Text(
                                  "入力問題",
                                  style: TextStyle(fontSize: 17),
                                )
                              ],
                            ),
                            TextFormField(
                              onChanged: (value) {
                                formChanged = true;
                              },
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
                              margin: const EdgeInsets.only(top: 15, bottom: 5),
                              child: FilledButton.icon(
                                onPressed: () {
                                  Picker(
                                          adapter: NumberPickerAdapter(data: [
                                            const NumberPickerColumn(
                                                begin: 1, end: 4),
                                          ]),
                                          changeToFirst: true,
                                          onConfirm:
                                              (Picker picker, List value) {
                                            setState(() {
                                              fieldAnswerNum = picker
                                                  .getSelectedValues()
                                                  .first;
                                            });
                                          },
                                          backgroundColor: Theme.of(context)
                                              .dialogBackgroundColor,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .headline6,
                                          cancelText: "キャンセル",
                                          confirmText: "決定")
                                      .showModal(context);
                                },
                                icon: const Icon(Icons.check),
                                label: Text(
                                  "正解の選択肢: $fieldAnswerNum番",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ))));
  }
}
