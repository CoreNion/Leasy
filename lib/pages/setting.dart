import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SettingPage extends StatefulHookConsumerWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton.icon(
          onPressed: ((() async {
            final db = File(p.join(await getDatabasesPath(), "study.db"));
            if (db.existsSync()) {
              db.deleteSync();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('削除したよ〜')));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('存在しないよ〜')));
            }
          })),
          icon: const Icon(Icons.delete_forever),
          label: const Text("study.dbを削除"),
        ),
      ],
    );
  }
}
