import 'package:flutter/material.dart';

import '../utility.dart';

/// 画面サイズに応じたダイアログを表示する
///
/// [context] ダイアログを表示するコンテキスト
///
/// [content] ダイアログの中身
///
/// [canPop] ダイアログを閉じれるか
///
/// [barTitle] AppBarのタイトル(nullの場合はAppBarを表示しない)
///
/// [dialogHeight] ダイアログの高さ指定
Future<T?> showResponsiveDialog<T>(BuildContext context, Widget content,
    {bool canPop = true, String? barTitle, double? dialogHeight}) async {
  if (checkLargeSC(context)) {
    return await showDialog(
        barrierDismissible: canPop,
        context: context,
        builder: (builder) {
          return WillPopScope(
              onWillPop: canPop ? null : () async => false,
              child: Dialog(
                child: SizedBox(
                  width: 700,
                  height: dialogHeight,
                  child: _ResponsiveDialogBase(
                      content: content, barTitle: barTitle),
                ),
              ));
        });
  } else {
    return await showModalBottomSheet(
        isDismissible: canPop,
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (builder) => WillPopScope(
            onWillPop: canPop ? null : () async => false,
            child: SizedBox(
                height: dialogHeight,
                child: _ResponsiveDialogBase(
                    content: content, barTitle: barTitle))));
  }
}

/// 可変ダイアログの基礎
///
/// [content] ダイアログの中身
///
/// [barTitle] AppBarのタイトル(nullの場合はAppBarを表示しない)
class _ResponsiveDialogBase extends StatelessWidget {
  final Widget content;
  final String? barTitle;

  const _ResponsiveDialogBase({required this.content, this.barTitle});

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
            child: SafeArea(
                child: barTitle != null
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        AppBar(
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          title: Text(barTitle!),
                          automaticallyImplyLeading: false,
                          leading: IconButton(
                              onPressed: (() => Navigator.of(context).pop()),
                              icon: const Icon(Icons.expand_more)),
                        ),
                        content,
                      ])
                    : content)));
  }
}
