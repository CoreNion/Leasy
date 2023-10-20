import 'dart:math';

import '../class/question.dart';
import '../class/section.dart';
import '../class/subject.dart';
import 'question.dart';
import 'section.dart';
import 'subject.dart';

/// デモ教科を作成する
Future<void> generateSubjectDemo() async {
  // 教科を作成
  final subject = SubjectInfo(
      title: "[デモ] 単語帳",
      id: Random().nextInt(4294967296),
      latestCorrect: 7,
      latestIncorrect: 3);
  await createSubject(subject);

  // セクションを作成
  final section = SectionInfo(
    title: "Lesson 1",
    tableID: Random().nextInt(4294967296),
    subjectID: subject.id,
    latestStudyMode: "normal",
  );
  await createSection(section);

  // 各問題のデータ
  final question = [
    "大丈夫",
    "十分",
    "見つける (過去形)",
    "馬",
    "重要",
    "丸い",
    "利口な・賢い",
    "おそらく",
    "金属",
    "不可能",
  ];
  final choice1 = [
    "alright",
    "already",
    "lost",
    "rapid",
    "important",
    "ball",
    "smart",
    "maybe",
    "bold",
    "impossible"
  ];
  final choice2 = [
    "right",
    "evidence",
    "look",
    "fuse",
    "impact",
    "round",
    "great",
    "however",
    "silcon",
    "impress"
  ];
  final choice3 = [
    "wrong",
    "enough",
    "found",
    "solid",
    "import",
    "except",
    "exceptance",
    "because",
    "lead",
    "imsure"
  ];
  final choice4 = [
    "enemy",
    "arrest",
    "funded",
    "horse",
    "imagine",
    "ring",
    "abstract",
    "while",
    "metal",
    "immeasurable"
  ];
  final answer = [1, 3, 3, 4, 1, 2, 1, 1, 4, 1];

  // 10問問題を作成する
  final qList = <MiQuestion>[];
  for (var i = 0; i < 10; i++) {
    qList.add(MiQuestion(
        id: Random().nextInt(4294967296),
        sectionID: section.tableID,
        question: question[i],
        latestCorrect: Random().nextBool(),
        choices: [choice1[i], choice2[i], choice3[i], choice4[i]],
        answer: answer[i],
        isInput: false,
        totalCorrect: Random().nextInt(24),
        totalInCorrect: Random().nextInt(24)));
  }
  await Future.wait(qList.map((e) => createQuestion(e)).toList());
}
