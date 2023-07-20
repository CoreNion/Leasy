import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../class/cloud.dart';
import '../helper/cloud/common.dart';
import '../main.dart';
import 'settings/general.dart';

/// アカウントにログイン/ログアウトするボタン
class AccountButton extends StatefulWidget {
  final bool reLogin;
  final void Function() parentSetState;

  const AccountButton({
    super.key,
    required this.parentSetState,
    this.reLogin = false,
  });

  @override
  State<AccountButton> createState() => AccountButtonState();
}

class AccountButtonState extends State<AccountButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return widget.reLogin || MyApp.cloudType == CloudType.none
        ? ElevatedButton.icon(
            onPressed: !loading
                ? () async {
                    late CloudType cloudType;
                    setState(() {
                      loading = true;
                    });

                    if (!widget.reLogin) {
                      final appleDevice =
                          !kIsWeb && (Platform.isIOS || Platform.isMacOS);

                      // 必ずお読みくださいを表示
                      final dialogRes = await showDialog<bool>(
                          context: context,
                          builder: (builder) => const WarningDialog(
                                titile: "必ずお読みください",
                                content:
                                    "クラウド同期機能を有効化すると、デバイスの起動時や新しいデータが保存されたときなどに、自動でクラウド上のデータと同期するようになります。\n複数端末で単語帳を同時に操作した場合、データに不具合が発生する可能性があるため、複数端末で同時に操作しないようにお願いします。\nデータは選択されたクラウドサービスに保存され、アカウントの容量が少量ですが利用されます。Leasyの運営元ではサーバーを用意していませんのでご注意ください。",
                                count: 10,
                              ));
                      if (!(dialogRes ?? false) || !mounted) {
                        setState(() {
                          loading = false;
                        });
                        return;
                      }

                      // どこのクラウドにログインするか尋ねる
                      final res = await showDialog<CloudType>(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              title: const Text("接続するクラウドを選択"),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.pop(context, CloudType.google);
                                  },
                                  child: const Text("Google Drive"),
                                ),
                                appleDevice
                                    ? SimpleDialogOption(
                                        onPressed: () {
                                          Navigator.pop(
                                              context, CloudType.icloud);
                                        },
                                        child: const Text("iCloud Documents"),
                                      )
                                    : Container(),
                              ],
                            );
                          });
                      if (res == null) {
                        setState(() {
                          loading = false;
                        });
                        return;
                      }

                      cloudType = res;
                    } else {
                      cloudType = MyApp.cloudType;

                      await CloudService.signOutTemporarily();
                    }

                    try {
                      if (!(await CloudService.signIn(cloudType))) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("ログインがキャンセルされました")));
                          setState(() {
                            loading = false;
                          });
                        }
                        return;
                      }
                    } catch (e) {
                      await CloudService.signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("ログインに失敗しました。もう一度お試しください。\n詳細: $e")));
                        setState(() {
                          loading = false;
                        });
                      }
                      return;
                    }

                    if (!widget.reLogin) {
                      try {
                        await saveToCloud();
                      } catch (e) {
                        await CloudService.signOut();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "ログインには成功しましたが、クラウドへの保存に失敗しました。\n詳細: $e")));
                          setState(() {
                            loading = false;
                          });
                        }
                      }
                    }

                    setState(() {
                      loading = false;
                    });
                    widget.parentSetState();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("ログイン完了")));
                    }
                  }
                : null,
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
                : const Icon(Icons.login),
            label: Text(widget.reLogin ? "再ログイン" : "ログインする"))
        : FilledButton.icon(
            onPressed: !loading
                ? () async {
                    await CloudService.signOut();
                    if (!mounted) return;

                    widget.parentSetState();

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ログアウトしました")));
                  }
                : null,
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
                : const Icon(Icons.logout),
            label: const Text("ログアウト"));
  }
}

/// クラウド上のデータを削除するボタン
///
/// クラウドに接続していない場合は空のコンテナを表示する
class RemoveDataButton extends StatefulWidget {
  final void Function() parentSetState;

  const RemoveDataButton({super.key, required this.parentSetState});

  @override
  State<RemoveDataButton> createState() => _RemoveDataButtonState();
}

class _RemoveDataButtonState extends State<RemoveDataButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MyApp.cloudType != CloudType.none
        ? ElevatedButton.icon(
            onPressed: !loading
                ? () async {
                    setState(() {
                      loading = true;
                    });

                    final res = await showDialog<bool>(
                        context: context,
                        builder: (builder) => const WarningDialog(
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

                    await CloudService.deleteCloudFile("study.db");
                    await CloudService.signOut();
                    if (!mounted) return;

                    setState(() {
                      loading = false;
                    });
                    widget.parentSetState();

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("クラウド上のデータを削除し、ログアウトしました。")));
                  }
                : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onErrorContainer,
                foregroundColor: colorScheme.errorContainer),
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
            label: const Text("データを削除"))
        : Container();
  }
}