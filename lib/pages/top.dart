import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../db_helper.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

/// トップの教科リストのState
final subjectListWidgetProvider = StateProvider((_) => <Widget>[]);

class TopPage extends StatefulHookConsumerWidget {
  const TopPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopPageState();

  /// 教科リストを生成する
  static Future<List<Widget>> createSubjectListWidget() async {
    final titles = await DataBaseHelper.getSubjectTitles();
    List<Widget> subjectListWidget = [];

    for (var title in titles) {
      subjectListWidget.add(
        Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
          ),
        ),
      );
    }

    return subjectListWidget;
  }
}

class _TopPageState extends ConsumerState<TopPage> {
  @override
  void initState() {
    super.initState();

    TopPage.createSubjectListWidget().then((list) {
      ref.watch(subjectListWidgetProvider.notifier).state = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectList = ref.watch(subjectListWidgetProvider);

    return ResponsiveGridList(
      minItemWidth: 250,
      horizontalGridMargin: 20,
      horizontalGridSpacing: 30,
      verticalGridSpacing: 30,
      verticalGridMargin: 20,
      children: subjectList,
    );
  }
}
