import 'dart:io';

import 'package:flutter/material.dart';

import '../../class/cloud.dart';
import '../../helper/cloud/common.dart';
import '../../helper/common.dart';
import '../../widgets/account_button.dart';
import '../../widgets/overview.dart';
import '../../widgets/settings/cloud.dart';

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

  void rebuildUI() {
    setState(() {
      _loadCloudData = CloudService.getCloudInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(25))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppBar(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            title: const Text("Cloud Sync"),
            automaticallyImplyLeading: false,
            leading: IconButton(
                onPressed: (() => Navigator.of(context).pop()),
                icon: const Icon(Icons.expand_more)),
          ),
          Container(
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        runSpacing: 10,
                        spacing: 10,
                        children: [
                          AccountButton(parentSetState: rebuildUI),
                          RemoveDataButton(parentSetState: rebuildUI),
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
          )
        ]),
      ),
    );
  }
}
