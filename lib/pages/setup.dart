import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:status_alert/status_alert.dart';

import '../class/cloud.dart';
import '../helper/cloud/common.dart';
import '../main.dart';
import '../widgets/account_button.dart';
import '../widgets/overview.dart';
import '../widgets/settings/cloud.dart';
import '../widgets/settings/general.dart';
import '../helper/common.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentview = 0;
  final List<Widget> contents = const [
    _FirstView(),
    _HowToContent(),
    _NoteDescContent(),
    _CloudSettingContent(),
    _SettingContent()
  ];

  final titles = ["Welcome to Leasy!", "使い方", "学習の管理", "クラウド同期の設定", "カスタマイズ"];
  final bottomButtonTexts = ["始める", "次へ", "次へ", "次へ", "始めましょう！"];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
        decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
                child: Column(
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
                Expanded(child: contents[currentview])
              ],
            )),
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
}

class _FirstView extends StatelessWidget {
  const _FirstView();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text(
        "Leasyをダウンロードしていただき、ありがとうございます！",
        style: TextStyle(fontSize: 20),
      ),
      Expanded(
        child: Align(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SvgPicture.asset(
              'assets/icon.svg',
              height: 200,
            ),
          ),
        ),
      )
    ]);
  }
}

class _HowToContent extends StatefulWidget {
  const _HowToContent();

  @override
  State<_HowToContent> createState() => __HowToContentState();
}

class __HowToContentState extends State<_HowToContent> {
  int currentview = 0;
  final PageController controller = PageController();
  List<bool> selectedInputType = [true, false];
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        currentview = currentview == 0 ? 1 : 0;
        controller.animateToPage(currentview,
            duration: const Duration(seconds: 1), curve: Curves.ease);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "このアプリは、自分で覚えたい単語やフレーズなどを登録して、4択問題や入力問題を通して暗記学習を進めるアプリです。",
          style: TextStyle(fontSize: 15),
        ),
        Expanded(
            child: Container(
          margin:
              const EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: colorScheme.background,
              border: Border.all(color: colorScheme.outline),
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currentview == 0 ? "問題の編集画面" : "学習画面",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              SizedBox.fromSize(size: const Size.fromHeight(10)),
              Expanded(
                child: PageView(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index) {
                      setState(() {
                        currentview = index;
                      });
                    },
                    children: <Widget>[
                      Column(children: [
                        ToggleButtons(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          constraints: const BoxConstraints(
                            minHeight: 40.0,
                            minWidth: 100.0,
                          ),
                          onPressed: (int index) {
                            setState(() {
                              for (int i = 0;
                                  i < selectedInputType.length;
                                  i++) {
                                selectedInputType[i] = (i == index);
                              }
                            });
                          },
                          isSelected: selectedInputType,
                          children: const <Widget>[
                            Text(
                              "4択問題",
                              style: TextStyle(fontSize: 17),
                            ),
                            Text(
                              "入力問題",
                              style: TextStyle(fontSize: 17),
                            )
                          ],
                        ),
                        TextFormField(
                            decoration: const InputDecoration(
                              labelText: "問題文",
                              icon: Icon(Icons.title),
                              hintText: "問題を入力",
                            ),
                            initialValue: "テスト問題",
                            readOnly: true),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: "1番目の選択肢",
                              icon: Icon(Icons.dashboard),
                              hintText: "選択肢に表示される文を入力"),
                          readOnly: true,
                          initialValue: "選択肢1",
                        ),
                        SizedBox.fromSize(size: const Size.fromHeight(5)),
                        const Icon(Icons.more_vert),
                        SizedBox.fromSize(size: const Size.fromHeight(5)),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check),
                          label: const Text(
                            "正解の選択肢: 1番",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ]),
                      Column(
                        children: <Widget>[
                          const Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    "問題 #1",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "テスト問題",
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          selectedInputType[0] == true
                              ? Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 5, bottom: 5),
                                      width: double.infinity,
                                      height: 100,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          StatusAlert.show(
                                            context,
                                            duration:
                                                const Duration(seconds: 1),
                                            title: '正解！',
                                            configuration:
                                                const IconConfiguration(
                                                    icon: Icons.check_circle),
                                            maxWidth: 260,
                                          );
                                          HapticFeedback.lightImpact();
                                        },
                                        child: const Text(
                                          "1: 選択肢1",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.more_vert)
                                  ],
                                )
                              : Container(
                                  margin: const EdgeInsets.all(10),
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: "解答",
                                        icon: Icon(Icons.dashboard),
                                        hintText: "解答を正確に入力"),
                                    readOnly: true,
                                  )),
                        ],
                      )
                    ]),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _NoteDescContent extends StatelessWidget {
  const _NoteDescContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Leasyでは、教科 -> セクション -> 問題の構造で学習を管理しています。\n基本的に問題の学習やテストは、各セクション内で行います。\nセクションを通して、お好みに問題をジャンルや範囲別などに分類してご利用ください。",
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 15),
        Stack(
          alignment: Alignment.topLeft,
          children: [
            Container(
              width: 350,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                color: colorScheme.primary,
              ),
              child: Align(
                alignment: const Alignment(0.83, 0),
                child: Text(
                  "教科",
                  style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
            Container(
              width: 250,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                color: colorScheme.secondary,
              ),
              child: Align(
                alignment: const Alignment(0.7, 0),
                child: Text(
                  "セクション",
                  style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                color: colorScheme.tertiary,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "問題",
                  style: TextStyle(
                      color: colorScheme.onTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _CloudSettingContent extends StatefulWidget {
  const _CloudSettingContent();

  @override
  State<_CloudSettingContent> createState() => __CloudSettingContentState();
}

class __CloudSettingContentState extends State<_CloudSettingContent> {
  late Future<CloudAccountInfo> _loadCloudData;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadCloudData = CloudService.getCloudInfo();
  }

  void rebuildUI() {
    setState(() {
      _loadCloudData = CloudService.getCloudInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text(
        "v1.2.0より、学習帳のデータをクラウドサービスにアップロードし、複数端末で同期して使えるようになりました！\nこの機能を利用する場合、GoogleドライブやiCloud(Appleデバイスのみ)でログインしてください。",
        style: TextStyle(fontSize: 15),
      ),
      const SizedBox(height: 15),
      FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return Column(children: [
              CheckCurrentStatus(
                accountInfo: snapshot.data!,
              ),
              const SizedBox(height: 10),
              AccountButton(parentSetState: rebuildUI),
            ]);
          } else {
            CloudService.signOut();
            return Align(
              alignment: Alignment.center,
              child: dialogLikeMessage(
                colorScheme,
                "エラーが発生しました",
                "クラウドの情報が取得できませんでした。アカウントはログアウトされました。もう一度お試しください。\n詳細: ${snapshot.error.toString()}",
              ),
            );
          }
        },
        future: _loadCloudData,
      )
    ]);
  }
}

class _SettingContent extends StatefulWidget {
  const _SettingContent();

  @override
  State<_SettingContent> createState() => __SettingContentState();
}

class __SettingContentState extends State<_SettingContent> {
  bool imported = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "テーマカラーやダークモードなどの設定を行います。",
          style: TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 15),
        const ScreenSettings(),
        const SizedBox(height: 10),
        !(MyApp.prefs.getBool("setup") ?? false)
            ? Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: colorScheme.background,
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
                child: ListTile(
                    title: const Text("学習データをインポート"),
                    subtitle: const Text("バックアップされたファイルから、学習データをインポートします。"),
                    trailing: loading
                        ? const CircularProgressIndicator()
                        : Icon(
                            imported ? Icons.check : Icons.upload,
                            color: colorScheme.primary,
                          ),
                    onTap: !imported
                        ? () async {
                            final dialogRes = await showDialog<bool>(
                                context: context,
                                builder: (builder) => const WarningDialog(
                                      content:
                                          "他人から受け取ったファイルを利用した場合、法令や内部規則などの違反行為となり罰せられる可能性があります。\nこの機能を利用したことにより利用者が損害を被った場合でも、Leasyの開発者は当該損害に関して一切責任を負いません。\nまた、開発者などがこの機能が不正に利用されていることを発見した場合、然るべき機関に報告することがあります。\nこれらに同意しますか？",
                                      count: 10,
                                    ));

                            if (!mounted || !(dialogRes ?? false)) return;
                            setState(() {
                              loading = true;
                            });

                            final res =
                                await importDataBase().catchError((e) async {
                              await showDialog(
                                  context: context,
                                  builder: (builder) => AlertDialog(
                                        title: const Text("エラー"),
                                        content: Text(
                                            "エラーが発生したため、データをインポート出来ませんでした。\n正しいファイルを選択しているかを確認してください。\n詳細:${e.toString()}"),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("OK"))
                                        ],
                                      ));
                              return false;
                            });

                            setState(() {
                              loading = false;
                            });
                            if (!res || !mounted) return;

                            HapticFeedback.lightImpact();
                            StatusAlert.show(
                              context,
                              duration: const Duration(seconds: 2),
                              title: 'インポート完了！',
                              subtitle:
                                  kIsWeb ? "設定が終了次第、ブラウザが再読み込みされます。" : null,
                              configuration: const IconConfiguration(
                                  icon: Icons.check_circle),
                              maxWidth: 300,
                            );
                            setState(() {
                              imported = true;
                            });
                          }
                        : null),
              )
            : Container(),
      ],
    );
  }
}
