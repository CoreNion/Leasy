import 'dart:io';

import 'package:flutter/material.dart';

import '../../class/cloud.dart';
import '../../helper/cloud/common.dart';
import '../../helper/cloud/google.dart';
import '../../helper/common.dart';
import '../../widgets/settings/cloud.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("クラウドに同期"),
      ),
      body: Container(
        margin: const EdgeInsets.all(17),
        child: FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CheckCurrentStatus(
                      accountInfo: snapshot.data!,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: snapshot.data!.type == CloudType.none
                            ? () async {
                                if (!(await MiGoogleService.signIn())) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("ログインがキャンセルされました")));
                                  return;
                                }

                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ログイン完了")));
                              }
                            : null,
                        child: const Text("ログインする")),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: () async {
                          if (!(await MiGoogleService.signIn())) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("ログインがキャンセルされました")));
                            return;
                          }

                          await MiGoogleService.uploadToAppFolder(
                              "study.db", File(studyDB.path));

                          final res =
                              (await MiGoogleService.getAppDriveFiles())!
                                  .map((e) => "${e.name} : ${e.modifiedTime}")
                                  .toList();

                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Google Driveに保存できました！\n$res")));
                        },
                        child: const Text("クラウドに保存する")),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () async {
                          await MiGoogleService.signOut();
                          if (!mounted) return;

                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("ログアウトしました")));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.onError,
                            foregroundColor: colorScheme.error),
                        child: const Text("ログアウト"))
                  ],
                );
              } else {
                return const Center(child: Text("エラーが発生しました"));
              }
            },
            future: getCloudInfo()),
      ),
    );
  }
}
