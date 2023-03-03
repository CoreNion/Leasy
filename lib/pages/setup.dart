import 'package:flutter/material.dart';
import 'package:mimosa/pages/setting.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentview = 0;
  late List<Widget> contents;

  final titles = ["Welcome to Leasy!", "使い方", "カスタマイズ"];
  final bottomButtonTexts = ["始める", "次へ", "始めましょう！"];

  @override
  void initState() {
    contents = [_firstView(), howtoContent(), _settingContent()];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
        decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    titles[currentview],
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                contents[currentview]
              ],
            ),
            Column(
              children: [
                FilledButton(
                    onPressed: () {
                      titles.length < currentview + 2
                          ? Navigator.pop(context)
                          : setState(
                              () {
                                currentview = currentview + 1;
                              },
                            );
                    },
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                      bottomButtonTexts[currentview],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    )),
              ],
            )
          ],
        ));
  }

  Widget _firstView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text(
          "Leasyをダウンロードしていただき、ありがとうございます！",
          style: TextStyle(fontSize: 16),
        ),
        Icon(
          Icons.handshake,
          size: 200,
        )
      ],
    );
  }

  Widget howtoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text(
          "使い方の動画などを置く予定",
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _settingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text(
          "テーマカラーやダークモードなどの設定を行います。",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 15),
        ScreenSettings()
      ],
    );
  }
}
