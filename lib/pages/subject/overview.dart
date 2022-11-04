import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubjectOverview extends StatefulHookConsumerWidget {
  final String title;
  const SubjectOverview({required this.title, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SubjectOverviewState();
}

class _SubjectOverviewState extends ConsumerState<SubjectOverview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Column(children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text("続きから学習を開始する"),
                    )),
                Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: ElevatedButton(
                        onPressed: null, child: Text("テストを開始する"))),
              ],
            ),
            const Divider(),
            Text(
              "セクション数:${1} 単語数:${1}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            )
          ]),
        )));
  }
}
