import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../db_helper.dart';

class SectionManagePage extends StatefulHookConsumerWidget {
  final QuestionModel? miQuestion;

  const SectionManagePage({super.key, this.miQuestion});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SectionManagePageState();
}

class _SectionManagePageState extends ConsumerState<SectionManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.miQuestion != null ? widget.miQuestion!.question : "新規作成する"),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: (() => Navigator.of(context).pop()),
            icon: const Icon(Icons.expand_more)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save))
        ],
      ),
      body: Container(
        height: 350.0,
        color: Colors.transparent,
        child: const Center(
          child: Text("Modal Seet"),
        ),
      ),
    );
  }
}
