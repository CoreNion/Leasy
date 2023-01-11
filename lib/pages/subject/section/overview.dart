import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SectionPage extends StatefulHookConsumerWidget {
  final int sectionID;
  final String sectionTitle;
  const SectionPage(
      {super.key, required this.sectionID, required this.sectionTitle});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SectionPageState();
}

class _SectionPageState extends ConsumerState<SectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.sectionTitle)),
        body: Padding(
          padding: const EdgeInsets.all(7.0),
          child: SingleChildScrollView(
              child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Padding(
                      padding: EdgeInsets.all(7.0),
                      child: ElevatedButton(
                        onPressed: null,
                        child: Text("続きから学習を開始する"),
                      )),
                  Padding(
                      padding: EdgeInsets.all(7.0),
                      child: ElevatedButton(
                          onPressed: null, child: Text("テストを開始する"))),
                ],
              ),
              const Divider(),
            ],
          )),
        ));
  }
}
