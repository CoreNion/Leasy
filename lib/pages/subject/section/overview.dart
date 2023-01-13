import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../../db_helper.dart';
import './manage.dart';

class SectionPage extends StatefulHookConsumerWidget {
  final int sectionID;
  final String subjectName;
  final String sectionTitle;
  const SectionPage(
      {super.key,
      required this.sectionID,
      required this.subjectName,
      required this.sectionTitle});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SectionPageState();
}

class _SectionPageState extends ConsumerState<SectionPage> {
  final List<String> _questionListStr = <String>[];

  @override
  void initState() {
    super.initState();

    // 保存されている問題をリストに追加
    DataBaseHelper.getQuestionsStrs(widget.sectionID).then((questions) async {
      for (var question in questions) {
        setState(() => _questionListStr.add(question));
      }
    });
  }

  final shape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.sectionTitle),
          actions: <Widget>[
            IconButton(
                onPressed: ((() => showBarModalBottomSheet(
                    context: context,
                    shape: shape,
                    builder: (builder) => const SectionManagePage()))),
                icon: const Icon(Icons.add)),
          ],
        ),
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
              // 要検討: セクション一覧のListViewとWidgetを共通化
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _questionListStr.length,
                  itemBuilder: ((context, index) => Dismissible(
                        key: Key(_questionListStr[index]),
                        onDismissed: (direction) async {
                          await DataBaseHelper.removeQuestion(
                              widget.sectionID, _questionListStr[index]);

                          setState(() {
                            _questionListStr.removeAt(index);
                          });

                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('削除しました')));
                        },
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('${index + 1}番目の問題を削除しますか？'),
                                content: const Text('この操作は取り消せません。'),
                                actions: [
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('はい'),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('いいえ'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const <Widget>[
                              Icon(Icons.delete),
                              Icon(Icons.delete)
                            ],
                          ),
                        ),
                        child: ListTile(
                            title: Text(_questionListStr[index]),
                            onTap: ((() => showBarModalBottomSheet(
                                context: context,
                                shape: shape,
                                builder: (builder) =>
                                    const SectionManagePage())))),
                      ))),
            ],
          )),
        ));
  }
}
