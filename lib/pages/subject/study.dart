import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:status_alert/status_alert.dart';

import '../../db_helper.dart';

class SectionStudyPage extends StatefulHookConsumerWidget {
  final SectionInfo? secInfo;
  final List<MiQuestion> miQuestions;
  final bool testMode;

  const SectionStudyPage(
      {super.key,
      this.secInfo,
      required this.miQuestions,
      required this.testMode});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SectionStudyPageState();
}

class _SectionStudyPageState extends ConsumerState<SectionStudyPage> {
  int currentQuestionIndex = 1;
  SectionInfo? secInfo;
  late MiQuestion currentMi;
  late List<MiQuestion> mis;
  late List<bool?> checkedAnswers;

  late bool setInputQuestion;

  late List<bool> record;

  final _formKey = GlobalKey<FormState>();
  late String inputAnswer;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    secInfo = widget.secInfo;
    mis = widget.miQuestions;
    checkedAnswers = List.filled(mis.length, null);
    record = List.filled(mis.length, false);

    // テストモードの場合は問題をシャッフル
    if (widget.testMode) {
      mis.shuffle();
    }

    // 最初に表示する問題を設定
    currentMi = mis.first;
    setInputQuestion = currentMi.isInput;
  }

  /// 指定された問題に表示を書き換える関数
  void setQuestionUI(int questionIndex) {
    // 上限未満場合のみ実行
    if (questionIndex <= mis.length) {
      setState(() {
        currentMi = mis[questionIndex - 1];
        currentQuestionIndex = questionIndex;
        setInputQuestion = currentMi.isInput;
      });
      // 入力問題の入力済みテキストを削除
      textController.clear();
    } else if (questionIndex > mis.length && !checkedAnswers.contains(null)) {
      // 最後の問題より上かつ全ての問題が解き終わっていたら終了するかを尋ねる
      showDialog<bool?>(
          context: context,
          builder: ((context) => AlertDialog(
                title: const Text("All Done!"),
                content: Text(
                    '最後の問題が終了しました。\n結果は、${record[0]}問正解/${record[1]}問不正解でした。\n学習モードを終了しますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('いいえ'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('はい'),
                  ),
                ],
              ))).then((isExit) async {
        if (isExit ?? false) {
          if (secInfo != null) {
            // DBに記録を保存
            await DataBaseHelper.updateSectionRecord(
                secInfo!.tableID, widget.testMode ? "test" : "normal");

            for (var i = 0; i < mis.length; i++) {
              await DataBaseHelper.updateQuestionRecord(
                  secInfo!.tableID, record[i], mis[i].id);
            }
          }

          Navigator.pop(context, record);
        }
      });
    }
  }

  /// 選択問題の解答部分
  Column multipleChoice() {
    final answered = checkedAnswers[currentQuestionIndex - 1] ?? false;

    return Column(
      children: currentMi.choices.asMap().entries.map((entry) {
        return Expanded(
            child: Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5),
          width: double.infinity,
          child: ElevatedButton(
            style: ButtonStyle(
                backgroundColor: (answered
                    ? ((currentMi.answer == entry.key + 1)
                        ? MaterialStateProperty.all(Colors.green)
                        : MaterialStateProperty.all(Colors.red))
                    : null),
                foregroundColor:
                    answered ? MaterialStateProperty.all(Colors.white) : null),
            onPressed: answered
                ? null
                : () {
                    setState(() {
                      checkedAnswers[currentQuestionIndex - 1] = true;
                    });

                    if (currentMi.answer == entry.key + 1) {
                      onCorrect(context);
                    } else {
                      onIncorrect(context, "${currentMi.answer}番");
                    }
                  },
            child: Text(
              "${entry.key + 1}: ${entry.value}",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ));
      }).toList(),
    );
  }

  /// 入力問題の解答部分
  Column inputChoice() {
    final answered = checkedAnswers[currentQuestionIndex - 1] ?? false;
    final correctAnswer = currentMi.choices[currentMi.answer - 1];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Form(
          key: _formKey,
          child: TextFormField(
            controller: textController,
            decoration: const InputDecoration(
                labelText: "解答",
                icon: Icon(Icons.dashboard),
                hintText: "解答を正確に入力"),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "解答を入力してください。";
              } else {
                inputAnswer = value;
                return null;
              }
            },
          ),
        ),
        Container(
            margin: const EdgeInsets.only(top: 5, bottom: 10),
            child: answered
                ? Text(
                    "正解: $correctAnswer",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.redAccent),
                  )
                : null),
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
              onPressed: answered
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          checkedAnswers[currentQuestionIndex - 1] = true;
                        });
                        if (inputAnswer == correctAnswer) {
                          onCorrect(context);
                        } else {
                          onIncorrect(context, correctAnswer);
                        }
                      }
                    },
              child: const Text("答え合わせ")),
        )
      ],
    );
  }

  /// 正解時の処理
  void onCorrect(BuildContext context) {
    const duration = Duration(seconds: 1);
    StatusAlert.show(
      context,
      duration: duration,
      title: '正解！',
      configuration: const IconConfiguration(icon: Icons.check_circle),
      maxWidth: 260,
    );

    // 正解を記録
    record[currentQuestionIndex - 1] = true;

    // 次の問題に進む
    Future.delayed(duration).then((value) {
      setQuestionUI(currentQuestionIndex + 1);
    });
  }

  /// 不正解時の処理
  void onIncorrect(BuildContext context, String correctAnswer) {
    const duration = Duration(milliseconds: 1500);
    StatusAlert.show(
      context,
      duration: duration,
      title: '不正解',
      subtitle: '正解は「$correctAnswer」です',
      configuration: const IconConfiguration(icon: Icons.close),
      maxWidth: 260,
    );

    // 不正解を記録
    record[currentQuestionIndex - 1] = false;

    if (widget.testMode) {
      // 次の問題に進む
      Future.delayed(duration).then((value) {
        setQuestionUI(currentQuestionIndex + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final answered = checkedAnswers[currentQuestionIndex - 1] ?? false;

    return WillPopScope(
        onWillPop: () async {
          // 最終問題が終わっていない場合は警告
          if (currentQuestionIndex < mis.length ||
              (currentQuestionIndex == mis.length && !answered)) {
            final res = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("確認"),
                    content: const Text("学習を終了しますか？\n途中で中断した場合、学習の記録は行いません。"),
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
            if (secInfo != null) {
              // DBに記録を保存
              await DataBaseHelper.updateSectionRecord(
                  secInfo!.tableID, widget.testMode ? "test" : "normal");

              for (var i = 0; i < mis.length; i++) {
                await DataBaseHelper.updateQuestionRecord(
                    secInfo!.tableID, record[i], mis[i].id);
              }
            }

            return true;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(secInfo != null ? secInfo!.title : "教科テスト"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "問題 #$currentQuestionIndex",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentMi.question,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                ),
                setInputQuestion
                    ? inputChoice()
                    : Expanded(flex: 3, child: multipleChoice()),
              ],
            ),
          ),
          bottomNavigationBar: widget.testMode
              ? null
              : BottomNavigationBar(
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  selectedFontSize: 0.0,
                  unselectedFontSize: 0.0,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.arrow_back_ios_new), label: '戻る'),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.arrow_forward_ios),
                      label: '進む',
                    )
                  ],
                  onTap: (selectedIndex) {
                    if (selectedIndex == 0 && currentQuestionIndex != 1) {
                      // 戻るボタン、最初の問題の場合は何もしない
                      setQuestionUI(currentQuestionIndex - 1);
                    } else if (selectedIndex == 1) {
                      // 進むボタン
                      setQuestionUI(currentQuestionIndex + 1);
                    }
                  },
                ),
        ));
  }
}
