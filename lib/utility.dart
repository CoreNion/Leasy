import 'package:flutter/material.dart';

/// 大画面の画面であるかをチェックする関数
bool checkLargeSC(BuildContext context) {
  if (MediaQuery.of(context).size.width > 1000) {
    return true;
  } else {
    return false;
  }
}
