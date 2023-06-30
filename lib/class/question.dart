/// 問題集のモデル
class MiQuestion {
  // 問題ID
  final int id;

  // 所属するセクションのID
  final int sectionID;

  // 問題文
  final String question;

  // 選択肢
  final List<String> choices;

  // 正解の選択肢の番号
  final int answer;

  // 入力形式かどうか
  final bool isInput;

  // 最新の正誤
  final bool? latestCorrect;

  // 合計正解数
  final int totalCorrect;

  // 合計不正解数
  final int totalInCorrect;

  MiQuestion(
      {required this.id,
      required this.sectionID,
      required this.question,
      required this.choices,
      required this.answer,
      required this.isInput,
      required this.totalCorrect,
      required this.totalInCorrect,
      this.latestCorrect});

  // DataBaseの形式のMapに変換する関数
  Map<String, Object?> toTableMap() {
    {
      return {
        'id': id,
        'question': question,
        'sectionID': sectionID,
        'choice1': choices[0],
        'choice2': choices[1],
        'choice3': choices[2],
        'choice4': choices[3],
        'answer': answer,
        'input': isInput ? 1 : 0,
        'latestCorrect':
            latestCorrect != null ? (latestCorrect! ? 1 : 0) : null,
        'totalCorrect': totalCorrect,
        'totalInCorrect': totalInCorrect
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static MiQuestion tableMapToModel(Map<String, Object?> map) {
    return MiQuestion(
        id: map["id"] as int,
        sectionID: map["sectionID"] as int,
        question: map["question"].toString(),
        choices: [
          map["choice1"].toString(),
          map["choice2"].toString(),
          map["choice3"].toString(),
          map["choice4"].toString()
        ],
        answer: map["answer"] as int,
        isInput: (map["input"] as int) == 1 ? true : false,
        latestCorrect: (map["latestCorrect"] as int?) != null
            ? ((map["latestCorrect"] as int) == 1 ? true : false)
            : null,
        totalCorrect: map["totalCorrect"] as int,
        totalInCorrect: map["totalInCorrect"] as int);
  }
}

/// 問題集の概要のモデル
class MiQuestionSummary {
  // 問題ID
  final int id;

  // 問題文
  final String question;

  // 最新の正誤
  final bool? latestCorrect;

  // 合計正解数
  final int totalCorrect;

  // 合計不正解数
  final int totalInCorrect;

  MiQuestionSummary(
      {required this.id,
      required this.question,
      required this.latestCorrect,
      required this.totalCorrect,
      required this.totalInCorrect});

  // DataBaseの形式のMapからModelに変換する関数
  static MiQuestionSummary tableMapToModel(Map<String, Object?> map) {
    return MiQuestionSummary(
        id: map["id"] as int,
        question: map["question"].toString(),
        latestCorrect: (map["latestCorrect"] as int?) != null
            ? ((map["latestCorrect"] as int) == 1 ? true : false)
            : null,
        totalCorrect: map["totalCorrect"] as int,
        totalInCorrect: map["totalInCorrect"] as int);
  }
}
