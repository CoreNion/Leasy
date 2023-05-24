import 'package:flutter/material.dart';
import 'package:status_alert/status_alert.dart';
import 'package:flutter/services.dart';

import '../../class/question.dart';
import '../../helper/question.dart';

class SectionStudyPage extends StatefulWidget {
  // 学習する問題のID
  final List<int> questionIDs;
  // テストモードかどうか
  final bool testMode;
  // アプリバーに表示されるタイトル
  final String? title;

  const SectionStudyPage(
      {super.key,
      required this.questionIDs,
      required this.testMode,
      this.title});

  @override
  State<StatefulWidget> createState() => _SectionStudyPageState();
}

class _SectionStudyPageState extends State<SectionStudyPage> {
  bool loading = true;

  // 現在の問題番号(Index)
  int currentQuestionIndex = 1;
  // 解答済みか
  bool answered = false;

  // 現在学習している問題
  late MiQuestion currentMi;
  // 学習する問題IDと解答状況
  late List<MapEntry<int, bool?>> records;
  // 入力問題にするか
  late bool setInputQuestion;

  final _formKey = GlobalKey<FormState>();
  late String inputAnswer;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // テストモードの場合は問題をシャッフル
    records =
        widget.questionIDs.map((e) => MapEntry<int, bool?>(e, null)).toList();
    if (widget.testMode) records.shuffle();

    // 最初に表示する問題を設定
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      currentMi = await getMiQuestion(records.first.key);
      setInputQuestion = currentMi.isInput;

      setState(() => loading = false);
    });

    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  /// キーボード検知時の処理
  bool _onKey(KeyEvent event) {
    if (!mounted) return false;
    final key = event.logicalKey.keyLabel;

    // KeyDownでかつDialogなどが表示されていない場合のみ実行
    if (event is KeyDownEvent && ModalRoute.of(context)?.isCurrent == true) {
      // 問題中に1~4のキーが押されたらそれで解答する
      if (!setInputQuestion && !answered && key.contains(RegExp(r'[1-4]'))) {
        // 解答後のUIにする
        setState(() => answered = true);

        if (currentMi.answer == int.parse(key)) {
          onCorrect(context);
        } else {
          onIncorrect(context);
        }
      } else if (!widget.testMode) {
        /* 左右キーが押された時の処理(通常学習モードのみ) */
        if (key == "Arrow Left" && currentQuestionIndex != 1) {
          // 問題を戻る、最初の問題の場合は何もしない
          setQuestion(currentQuestionIndex - 1);
        } else if (key == "Arrow Right") {
          // 問題を進む
          setQuestion(currentQuestionIndex + 1);
        }
      }
    }

    return false;
  }

  /// 指定された問題に表示を書き換える関数
  Future<void> setQuestion(int questionIndex) async {
    // 上限未満場合のみ実行
    if (questionIndex <= records.length) {
      setState(() => loading = true);
      // 問題を取得し、Indexなどを設定
      currentMi = await getMiQuestion(records[questionIndex - 1].key);
      setState(() {
        setInputQuestion = currentMi.isInput;
        answered = records[questionIndex - 1].value != null;

        // 入力問題の入力済みテキストを削除
        textController.clear();

        currentQuestionIndex = questionIndex;
        loading = false;
      });
    } else if (questionIndex > records.length &&
        !records.map((e) => e.value).contains(null)) {
      final correct = records.where((e) => e.value == true).length;
      final incorrect = records.where((e) => e.value == false).length;

      // 最後の問題より上かつ全ての問題が解き終わっていたら終了するかを尋ねる
      showDialog<bool?>(
          context: context,
          builder: ((context) => AlertDialog(
                title: const Text("All Done!"),
                content: Text(
                    '最後の問題が終了しました。\n結果は、$correct問正解・$incorrect問不正解でした。\n学習モードを終了しますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('いいえ'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..pop(records);
                    },
                    child: const Text('はい'),
                  ),
                ],
              )));
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
                    // 解答後のUIにする
                    setState(() => answered = true);

                    if (currentMi.answer == entry.key + 1) {
                      onCorrect(context);
                    } else {
                      onIncorrect(context);
                    }
                  },
            child: Text(
              "${entry.key + 1}: ${entry.value}",
              style: const TextStyle(fontSize: 20),
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
          child: FilledButton(
              onPressed: answered
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        // 解答後のUIにする
                        setState(() => answered = true);

                        if (inputAnswer == correctAnswer) {
                          onCorrect(context);
                        } else {
                          onIncorrect(context);
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
    HapticFeedback.lightImpact();

    setState(() {
      // 正解を記録
      records[currentQuestionIndex - 1] =
          MapEntry(records[currentQuestionIndex - 1].key, true);
    });

    // 次の問題に進む
    Future.delayed(duration).then((value) {
      setQuestion(currentQuestionIndex + 1);
    });
  }

  /// 不正解時の処理
  void onIncorrect(BuildContext context) {
    const duration = Duration(milliseconds: 1500);
    StatusAlert.show(
      context,
      duration: duration,
      title: '不正解',
      subtitle: '正解は「${currentMi.choices[currentMi.answer - 1]}」です',
      configuration: const IconConfiguration(icon: Icons.close),
      maxWidth: 260,
    );
    HapticFeedback.heavyImpact().then((value) async {
      await Future.delayed(const Duration(milliseconds: 250));
      HapticFeedback.heavyImpact();
    });

    // 不正解を記録
    setState(() {
      records[currentQuestionIndex - 1] =
          MapEntry(records[currentQuestionIndex - 1].key, false);
    });

    // 次の問題に進む
    Future.delayed(duration).then((value) {
      setQuestion(currentQuestionIndex + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // 全問題が終わっていない場合は警告
          if (records.map((e) => e.value).contains(null)) {
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
            Navigator.pop(context, records);

            return false;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title != null ? widget.title! : "教科テスト"),
          ),
          body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
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
                            loading ? "" : currentMi.question,
                            style: const TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : (setInputQuestion
                          ? inputChoice()
                          : Expanded(flex: 3, child: multipleChoice())),
                ],
              ))),
          bottomNavigationBar: widget.testMode
              ? null
              : BottomNavigationBar(
                  selectedItemColor:
                      BottomNavigationBarTheme.of(context).unselectedItemColor,
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
                  onTap: loading
                      ? null
                      : (selectedIndex) {
                          if (selectedIndex == 0 && currentQuestionIndex != 1) {
                            // 戻るボタン、最初の問題の場合は何もしない
                            setQuestion(currentQuestionIndex - 1);
                          } else if (selectedIndex == 1) {
                            // 進むボタン
                            setQuestion(currentQuestionIndex + 1);
                          }
                        },
                ),
        ));
  }
}
