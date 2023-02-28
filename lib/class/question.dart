/// セクションの問題集のモデル
class MiQuestion {
  final int id;

  final String question;

  final List<String> choices;

  final int answer;

  final bool isInput;

  final bool? latestCorrect;

  MiQuestion(
      {required this.id,
      required this.question,
      required this.choices,
      required this.answer,
      required this.isInput,
      this.latestCorrect});

  // DataBaseの形式のMapに変換する関数
  Map<String, Object?> toTableMap() {
    {
      return {
        'id': id,
        'question': question,
        'choice1': choices[0],
        'choice2': choices[1],
        'choice3': choices[2],
        'choice4': choices[3],
        'answer': answer,
        'input': isInput ? 1 : 0,
        'latestCorrect': latestCorrect != null ? (latestCorrect! ? 1 : 0) : null
      };
    }
  }

  // DataBaseの形式のMapからModelに変換する関数
  static MiQuestion tableMapToModel(Map<String, Object?> map) {
    return MiQuestion(
        id: map["id"] as int,
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
            : null);
  }
}
