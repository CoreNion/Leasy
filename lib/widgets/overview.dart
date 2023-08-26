import 'package:flutter/material.dart';

/// 前回の成績を表示するスコアボード
Column scoreBoard(ColorScheme colorScheme, int correct, int inCorrect) {
  const boardRadius = Radius.circular(10);
  const boardPadding = EdgeInsets.all(10.0);
  const scoreTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
  final boardBorder = Border.all(color: Colors.white);

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Container(
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: boardPadding,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.blue.shade900,
            border: boardBorder,
            borderRadius: const BorderRadius.only(
                topLeft: boardRadius, topRight: boardRadius)),
        child: const Text(
          "前回の学習の結果",
          style: scoreTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
              child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 10),
            padding: boardPadding,
            decoration: BoxDecoration(
              color: Colors.green.shade900,
              border: boardBorder,
              borderRadius: const BorderRadius.only(bottomLeft: boardRadius),
            ),
            child: Text(
              "正解: $correct問",
              style: scoreTextStyle,
              textAlign: TextAlign.center,
            ),
          )),
          Expanded(
              child: Container(
            margin: const EdgeInsets.only(bottom: 10, right: 10),
            padding: boardPadding,
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              border: boardBorder,
              borderRadius: const BorderRadius.only(bottomRight: boardRadius),
            ),
            child: Text(
              "不正解: $inCorrect問",
              style: scoreTextStyle,
              textAlign: TextAlign.center,
            ),
          )),
        ],
      )
    ],
  );
}

/// 教科などが無い時に出る、ダイアログライクなメッセージ
ConstrainedBox dialogLikeMessage(
    ColorScheme colorScheme, String title, String content,
    {List<Widget>? actions}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: colorScheme.background,
          border: Border.all(color: colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const Divider(),
          SizedBox.fromSize(size: const Size.fromHeight(10)),
          Text(content, style: const TextStyle(fontSize: 17)),
          SizedBox.fromSize(size: const Size.fromHeight(10)),
          if (actions != null)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)
        ],
      ),
    ),
  );
}
