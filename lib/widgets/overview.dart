import 'package:flutter/material.dart';

/// 前回の成績を表示するスコアボード
Column scoreBoard(
    ColorScheme colorScheme, bool isTestMode, int correct, int inCorrect) {
  final isDarkMode = colorScheme.brightness == Brightness.dark;

  const boardRadius = Radius.circular(10);
  const boardPadding = EdgeInsets.all(10.0);
  const scoreTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  final boardBorder =
      Border.all(color: isDarkMode ? Colors.white : Colors.black);

  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Container(
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: boardPadding,
        width: double.infinity,
        decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            border: boardBorder,
            borderRadius: const BorderRadius.only(
                topLeft: boardRadius, topRight: boardRadius)),
        child: Text(
          "前回の${isTestMode ? "テスト" : "学習"}の結果",
          style: const TextStyle(fontSize: 20),
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
              color: colorScheme.secondaryContainer,
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
              color: colorScheme.errorContainer,
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
