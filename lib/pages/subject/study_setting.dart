import 'package:flutter/material.dart';

import '../../class/question.dart';
import '../../class/section.dart';
import '../../class/study.dart';
import '../../helper/question.dart';

/// 学習モードを選択するページ
class StudySettingPage<T> extends StatefulWidget {
  const StudySettingPage(
      {super.key,
      required this.studyMode,
      required this.questionsOrSections,
      this.endToDo});

  // 最初に選択されている学習モード
  final StudyMode studyMode;
  // セクション情報または問題情報
  final List<T> questionsOrSections;
  // 学習が終了したときに実行する処理 (ページとして扱わない場合の処理)
  final Function(StudySettings)? endToDo;

  @override
  State<StudySettingPage> createState() => _StudySettingPageState();
}

class _StudySettingPageState extends State<StudySettingPage>
    with TickerProviderStateMixin {
  // 実施する学習モード
  late StudyMode selectedStudyMode;
  // 不正解の問題のみ学習するか
  bool onlyIncorrect = false;
  // 出題する問題の正答確率の基準
  double sliderValue = 100;
  // 渡されたセクション情報や問題
  List<SectionInfo> origSections = [];
  List<MiQuestionSummary> origQuestions = [];

  // 選別された問題
  List<MiQuestionSummary> sendQuestions = [];

  // エラーメッセージ
  String errorMassage = "";
  // ローディング状態か
  bool loading = false;
  // 開始ボタンのアニメーション
  AnimationController? playController;

  @override
  void initState() {
    super.initState();
    selectedStudyMode = widget.studyMode;

    if (widget.questionsOrSections is List<SectionInfo>) {
      origSections = widget.questionsOrSections as List<SectionInfo>;
    } else {
      origQuestions = widget.questionsOrSections as List<MiQuestionSummary>;
    }

    // エラー時にボタンを左右に揺らすようにする
    playController = AnimationController(
        duration: const Duration(milliseconds: 50), vsync: this);
    // アニメーションが終了したら逆再生する
    playController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        playController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        playController!.forward();
      }
    });
  }

  @override
  void dispose() {
    playController!.dispose();
    super.dispose();
  }

  // 開始ボタンを500ms間左右に揺らす
  void playAnimation() {
    playController!.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      playController!.reset();
      playController!.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ToggleButtons(
            constraints: const BoxConstraints(
              minHeight: 35.0,
              minWidth: 150.0,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            isSelected: <bool>[
              selectedStudyMode == StudyMode.study,
              selectedStudyMode == StudyMode.test,
            ],
            onPressed: loading
                ? null
                : (index) {
                    setState(() {
                      selectedStudyMode = StudyMode.values[index];
                    });
                  },
            children: const <Widget>[
              Text("学習モード"),
              Text("テストモード"),
            ]),
        const SizedBox(height: 10),
        SwitchListTile(
            title: const Text("不正解の問題のみ学習"),
            secondary: Icon(
              Icons.note,
              color: colorScheme.primary,
            ),
            value: onlyIncorrect,
            onChanged: loading
                ? null
                : (val) => setState(() {
                      onlyIncorrect = val;
                    })),
        const SizedBox(height: 10),
        ListTile(
            leading:
                Icon(Icons.format_list_numbered, color: colorScheme.primary),
            title: const Text("出題する問題の正答確率の基準"),
            subtitle: const Text("設定した正答確率を下回る問題が出題されるようになります。"),
            trailing: Text("${sliderValue.round().toString()}%",
                style: const TextStyle(fontSize: 17))),
        Slider(
            value: sliderValue,
            min: 50,
            max: 100,
            divisions: 10,
            label: "${sliderValue.round().toString()}%",
            onChanged: loading
                ? null
                : (val) => setState(() {
                      sliderValue = val;
                    })),
        Text(errorMassage, style: TextStyle(color: colorScheme.error)),
        // エラー時にボタンを上下左右に揺らす
        AnimatedBuilder(
            animation: playController!,
            builder: (context, child) {
              return Transform.translate(
                  offset: Offset(5 * playController!.value, 0), child: child);
            },
            child: Container(
                margin: const EdgeInsets.all(15),
                child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: loading
                        ? null
                        : () async {
                            setState(() {
                              loading = true;
                            });

                            if (origQuestions.isEmpty) {
                              // 教科にあるすべての問題を取得
                              for (final sec in origSections) {
                                origQuestions.addAll(
                                    await getMiQuestionSummaries(sec.tableID));
                              }
                            }

                            // 問題を選別
                            if (onlyIncorrect) {
                              // 直近不正解の問題のみに絞る
                              sendQuestions = origQuestions
                                  .where((q) => !(q.latestCorrect ?? false))
                                  .toList();
                            } else {
                              sendQuestions = origQuestions;
                            }

                            // 正答率の基準を下回る問題のみに絞る
                            sendQuestions = sendQuestions.where((q) {
                              // 未回答の問題は基準以下とみなす
                              final totalAnswer =
                                  q.totalCorrect + q.totalInCorrect;
                              if (totalAnswer == 0) return true;

                              return (q.totalCorrect /
                                          (q.totalCorrect + q.totalInCorrect)) *
                                      100 <=
                                  sliderValue;
                            }).toList();

                            if (sendQuestions.isEmpty && mounted) {
                              setState(() {
                                loading = false;
                                errorMassage = "条件に合う問題が見つかりませんでした。";
                              });
                              playAnimation();
                              return;
                            }

                            setState(() {
                              loading = false;
                            });

                            // 設定を所定の方向に送る
                            final settings = StudySettings(selectedStudyMode,
                                sendQuestions.map((e) => e.id).toList());
                            if (widget.endToDo != null) {
                              // ToDoを実行
                              widget.endToDo!(settings);
                            } else {
                              // 前ページに結果を返す
                              if (!mounted) return;
                              Navigator.pop(context, settings);
                            }
                          },
                    icon: loading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: CircularProgressIndicator(
                              color: colorScheme.onSurface,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text("${selectedStudyMode.toString()}を開始",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17))))),
      ],
    );
  }
}
