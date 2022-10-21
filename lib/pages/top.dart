import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../db_helper.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class TopPage extends StatefulHookConsumerWidget {
  const TopPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopPageState();
}

class _TopPageState extends ConsumerState<TopPage> {
  List<Widget> subjectList = <Widget>[];

  @override
  void initState() {
    super.initState();

    DataBaseHelper.getSubjectTitles().then((list) {
      for (var i = 0; i < list.length; i++) {
        subjectList.add(
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border:
                  Border.all(color: Theme.of(context).colorScheme.onBackground),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              list[i],
            ),
          ),
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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
