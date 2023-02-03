import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/db_helper.dart';
import 'package:status_alert/status_alert.dart';

class SectionStudyPage extends StatefulHookConsumerWidget {
  final int sectionID;
  final String sectionTitle;
  final List<MiQuestion> miQuestions;

  const SectionStudyPage({
    super.key,
    required this.sectionID,
    required this.sectionTitle,
    required this.miQuestions,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SectionStudyPageState();
}

class _SectionStudyPageState extends ConsumerState<SectionStudyPage> {
  int currentQuestionIndex = 1;
  late MiQuestion currentMi;
  late List<MiQuestion> mis;
  bool answered = false;
  late bool setInputQuestion;

  final _formKey = GlobalKey<FormState>();
  late String inputAnswer;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 最初に表示する問題を設定
    mis = widget.miQuestions;
    currentMi = mis.first;
    setInputQuestion = currentMi.isInput;
  }

  /// 指定された問題に表示を書き換える関数
  void setQuestionUI(int questionIndex) {
    // 上限未満場合のみ実行
    if (questionIndex <= mis.length) {
      setState(() {
        answered = false;
        currentMi = mis[questionIndex - 1];
        currentQuestionIndex = questionIndex;
        setInputQuestion = currentMi.isInput;
      });
      // 入力問題の入力済みテキストを削除
      textController.clear();
    } else if (questionIndex > mis.length) {
      // 最後の問題より上の数だったら終了するかを尋ねる
      showDialog<bool?>(
          context: context,
          builder: ((context) => AlertDialog(
                title: const Text("お知らせ"),
                content: const Text('最後の問題が終了しました。学習モードを終了しますか？'),
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
              ))).then((isExit) {
        if (isExit ?? false) {
          Navigator.pop(context);
        }
      });
    }
  }

  /// 選択問題の解答部分
  Column multipleChoice() {
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
                      answered = true;
                    });

                    if (currentMi.answer == entry.key + 1) {
                      onCorrect(context);
                    } else {
                      StatusAlert.show(
                        context,
                        duration: const Duration(milliseconds: 1500),
                        title: '不正解',
                        subtitle: '正解は${currentMi.answer}番です',
                        configuration:
                            const IconConfiguration(icon: Icons.close),
                        maxWidth: 260,
                      );
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    answered = true;
                  });
                  if (inputAnswer == correctAnswer) {
                    onCorrect(context);
                  } else {
                    StatusAlert.show(
                      context,
                      duration: const Duration(milliseconds: 1500),
                      title: '不正解',
                      subtitle: '正解は「$correctAnswer」です',
                      configuration: const IconConfiguration(icon: Icons.close),
                      maxWidth: 260,
                    );
                  }
                }
              },
              child: const Text("答え合わせ")),
        )
      ],
    );
  }

  // 正解時の処理
  void onCorrect(BuildContext context) {
    const duration = Duration(seconds: 1);
    StatusAlert.show(
      context,
      duration: duration,
      title: '正解！',
      configuration: const IconConfiguration(icon: Icons.check_circle),
      maxWidth: 260,
    );

    // 次の問題に進む
    Future.delayed(duration).then((value) {
      setQuestionUI(currentQuestionIndex + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.sectionTitle),
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
              Expanded(
                  flex: 3,
                  child: setInputQuestion ? inputChoice() : multipleChoice()),
            ],
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 40,
          child: BottomNavigationBar(
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
