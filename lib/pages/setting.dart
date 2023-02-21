import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton.icon(
          onPressed: ((() async {
            final path = (await getApplicationSupportDirectory()).path;
            final db = File(p.join(path, "study.db"));
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
