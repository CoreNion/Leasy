import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../class/dictonary/english.dart';
import '../../../class/question.dart';
import '../../../utility.dart';

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

  /// 選択肢の入力形式 (4択問題/入力問題)
  late List<bool> selectedInputType;

  /// 問題文
  late String fieldQuestion;

  /// 選択肢
  final List<String> fieldChoices = List.filled(4, "");

  /// 問題文/選択肢のテキスト保存用コントローラー
  late List<TextEditingController> fieldTextEdits = [];

  /// 正解の選択肢の番号
  late int fieldAnswerNum;

  /// 単語補充がロード中か
  bool loading = false;

  /// 単語補充のエラーメッセージ
  String? errorMessage;

  final shape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  );

  TextFormField _selectField(int number) {
    return TextFormField(
      onChanged: (value) {
        formChanged = true;
      },
      decoration: InputDecoration(
          labelText:
              "$number番目の選択肢 (${fieldAnswerNum == number ? "正解" : "不正解"})",
          icon: Radio(
            value: number,
            groupValue: fieldAnswerNum,
            onChanged: (value) {
              formChanged = true;
              setState(() {
                fieldAnswerNum = value!;
              });
            },
          ),
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
                            // ignore: use_build_context_synchronously
                            if (await _confirmExit(context)) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          }),
                          icon: const Icon(Icons.expand_more)),
                      actions: [
                        IconButton(
                            onPressed: () async {
                              // フォームに変化があった時のみ保存する
                              if (!formChanged) {
                                Navigator.of(context).pop();
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                final miQuestion = MiQuestion(
                                    id: mi != null
                                        ? mi!.id
                                        : DateTime.now().millisecondsSinceEpoch,
                                    question: fieldQuestion,
                                    choices: fieldChoices,
                                    answer: fieldAnswerNum,
                                    isInput: selectedInputType[1],
                                    sectionID: widget.sectionID,
                                    totalCorrect: 0,
                                    totalInCorrect: 0);

                                Navigator.pop(context, miQuestion);
                              }
                            },
                            icon: const Icon(Icons.save))
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.all(checkLargeSC(context) ? 20.0 : 7.0),
                      decoration: BoxDecoration(
                          color: colorScheme.background,
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20))),
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
                            const SizedBox(height: 10),
                            FilledButton.icon(
                                onPressed: !loading
                                    ? () async {
                                        setState(() {
                                          loading = true;
                                          errorMessage = null;
                                          formChanged = true;
                                        });

                                        // 辞書の形式に合うように、検索用の単語はすべて小文字にする
                                        final answer =
                                            fieldTextEdits[fieldAnswerNum]
                                                .text
                                                .toLowerCase();

                                        // 英語の辞書を読み込む
                                        final json = await rootBundle.loadString(
                                            "assets/dictonary/english_sortby_pos.json");
                                        final dict = EnglishDictonary.fromJson(
                                            jsonDecode(json));

                                        if (!(dict.search(answer))) {
                                          setState(() {
                                            errorMessage =
                                                "この単語は辞書に存在しないため、選択肢に追加できませんでした。";
                                            loading = false;
                                          });
                                          return;
                                        }

                                        // 品詞を取得
                                        final partOfSpeech =
                                            dict.partOfSpeech(answer);

                                        // 選択肢に追加 (正解の選択肢/問題文はパス)
                                        for (int i = 1;
                                            i < fieldTextEdits.length;
                                            i++) {
                                          if (i == fieldAnswerNum) {
                                            continue;
                                          }

                                          fieldTextEdits[i].text =
                                              dict.randomWord(partOfSpeech);
                                        }

                                        setState(() {
                                          loading = false;
                                        });
                                      }
                                    : null,
                                icon: !loading
                                    ? const Icon(Icons.add)
                                    : const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                label: const Text("不正解の選択肢の単語を補充")),
                            const SizedBox(height: 10),
                            errorMessage != null
                                ? Text(errorMessage!,
                                    style: const TextStyle(color: Colors.red))
                                : Container(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))));
  }
}
