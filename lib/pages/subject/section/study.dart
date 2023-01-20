import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mimosa/db_helper.dart';

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

  @override
  void initState() {
    super.initState();

    mis = widget.miQuestions;
    currentMi = mis.first;
  }

  /// 指定された問題に置き換える関数
  void setQuestionUI(int questionIndex) {
    // 上限に当てはまる場合のみ実行
    if (questionIndex <= mis.length) {
      setState(() {
        currentMi = mis[questionIndex - 1];
        currentQuestionIndex = questionIndex;
      });
    }
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
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.blue,
                ),
                flex: 3,
              )
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
