import 'dart:io';

import 'package:flutter/material.dart';

import '../../class/cloud.dart';
import '../../helper/cloud/common.dart';
import '../../helper/common.dart';
import '../../widgets/overview.dart';
import '../../widgets/settings/cloud.dart';
import '../../widgets/settings/general.dart';

class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  late Future<CloudAccountInfo> _loadCloudData;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadCloudData = CloudService.getCloudInfo();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloud Sync"),
      ),
      body: Container(
        margin: const EdgeInsets.all(17),
        child: FutureBuilder(
          future: _loadCloudData,
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
                          onPressed: loading
                              ? null
                              : () async {
                                  setState(() {
                                    loading = true;
                                  });

                                  await CloudService.uploadFile(
                                      "study.db", File(studyDB.path));

                                  setState(() {
                                    loading = false;
                                    _loadCloudData =
                                        CloudService.getCloudInfo();
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("同期が完了しました")));
                                  }
                                },
                          icon: loading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: CircularProgressIndicator(
                                    color: colorScheme.onSurface,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: const Text("今すぐ同期する"))
                      : const SizedBox(),
                  const SizedBox(height: 20),
                  snapshot.data!.type == CloudType.none
                      ? ElevatedButton(
                          onPressed: () async {
                            final appleDevice =
                                Platform.isIOS || Platform.isMacOS;

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
                                        child: const Text("Google Drive"),
                                      ),
                                      appleDevice
                                          ? SimpleDialogOption(
                                              onPressed: () {
                                                Navigator.pop(
                                                    context, CloudType.icloud);
                                              },
                                              child: const Text(
                                                  "iCloud Documents"),
                                            )
                                          : Container(),
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
                                    SnackBar(
                                        content: Text(
                                            "ログインに失敗しました。もう一度お試しください。\n詳細: $e")));
                              }
                              return;
                            }

                            setState(() {
                              _loadCloudData = CloudService.getCloudInfo();
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("ログイン完了")));
                            }
                          },
                          child: const Text("ログインする"))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                                onPressed: () async {
                                  await CloudService.signOut();
                                  if (!mounted) return;

                                  setState(() {
                                    _loadCloudData =
                                        CloudService.getCloudInfo();
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("ログアウトしました")));
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text("ログアウト")),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        setState(() {
                                          loading = true;
                                        });

                                        final res = await showDialog<bool>(
                                            context: context,
                                            builder: (builder) =>
                                                const WarningDialog(
                                                  content:
                                                      "クラウド上にあるデータを削除します。よろしいですか？\nこの操作は取り消せません。",
                                                  count: 7,
                                                ));
                                        if (res != true) {
                                          setState(() {
                                            loading = false;
                                          });
                                          return;
                                        }

                                        await CloudService.deleteCloudFile(
                                            "study.db");
                                        await CloudService.signOut();
                                        if (!mounted) return;

                                        setState(() {
                                          loading = false;
                                          _loadCloudData =
                                              CloudService.getCloudInfo();
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "クラウド上のデータを削除し、ログアウトしました。")));
                                      },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.onErrorContainer,
                                    foregroundColor:
                                        colorScheme.errorContainer),
                                icon: loading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onSurface,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.delete),
                                label: const Text("データを削除")),
                          ],
                        ),
                ],
              );
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
        ),
      ),
    );
  }
}
