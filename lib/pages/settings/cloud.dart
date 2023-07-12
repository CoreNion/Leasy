import 'dart:io';

import 'package:flutter/material.dart';

import '../../class/cloud.dart';
import '../../helper/cloud/common.dart';
import '../../helper/common.dart';
import '../../widgets/settings/cloud.dart';
import '../../main.dart';

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
                    const SizedBox(height: 10),
                    snapshot.data!.type != CloudType.none &&
                            snapshot.data!.lastSyncTime != null
                        ? Text(
                            "最終同期: ${snapshot.data!.lastSyncTime?.toLocal().toString() ?? "一回も同期されていません"}")
                        : const SizedBox(),
                    const SizedBox(height: 10),
                    snapshot.data!.type != CloudType.none
                        ? ElevatedButton.icon(
                            onPressed: () async {
                              if (!(await CloudService.signIn(
                                  MyApp.cloudType))) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("ログインがキャンセルされました")));
                                return;
                              }

                              await CloudService.uploadFile(
                                  "study.db", File(studyDB.path));

                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("同期が完了しました！")));
                              }
                            },
                            icon: const Icon(Icons.sync),
                            label: const Text("今すぐ同期する"))
                        : const SizedBox(),
                    const SizedBox(height: 20),
                    snapshot.data!.type == CloudType.none
                        ? ElevatedButton(
                            onPressed: () async {
                              // どこのクラウドにログインするか尋ねる
                              final cloudType = await showDialog<CloudType>(
                                  context: context,
                                  builder: (context) {
                                    return SimpleDialog(
                                      title: const Text("接続するクラウドを選択"),
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, CloudType.google);
                                          },
                                          child: const Text("Google"),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, CloudType.icloud);
                                          },
                                          child: const Text("iCloud"),
                                        ),
                                      ],
                                    );
                                  });
                              if (cloudType == null) return;

                              try {
                                if (!(await CloudService.signIn(cloudType))) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("ログインがキャンセルされました")));
                                  }
                                  return;
                                }
                              } catch (e) {
                                await CloudService.signOut();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "ログインに失敗しました。もう一度お試しください。")));
                                }
                                return;
                              }

                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("ログイン完了")));
                              }
                            },
                            child: const Text("ログインする"))
                        : ElevatedButton(
                            onPressed: () async {
                              await CloudService.signOut();
                              if (!mounted) return;

                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("ログアウトしました")));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.onError,
                                foregroundColor: colorScheme.error),
                            child: const Text("ログアウト")),
                  ],
                );
              } else {
                return const Center(child: Text("エラーが発生しました"));
              }
            },
            future: CloudService.getCloudInfo()),
      ),
    );
  }
}
