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

  /// 教科Widget生成する
  static Widget createSubjectWidget(String title) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 15, left: 15),
          child: MaterialButton(
            minWidth: double.infinity,
            height: 150,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onPressed: null,
            onLongPress: () {},
            color: Colors.blueAccent,
            child: Text(
              title,
            ),
          ),
        ),
        Positioned(
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.remove),
              color: Colors.black,
              onPressed: () async {
                await DataBaseHelper.removeSubject(title);
                print("removed");
              },
              splashRadius: 0.1,
            ),
          ),
        )
      ],
    );
  }
}

class _TopPageState extends ConsumerState<TopPage> {
  @override
  void initState() {
    super.initState();

    DataBaseHelper.getSubjectTitles().then((titles) {
      for (var title in titles) {
        setState(() {
          ref
              .watch(subjectListWidgetProvider.notifier)
              .state
              .add(TopPage.createSubjectWidget(title));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectList = ref.watch(subjectListWidgetProvider);

    return ResponsiveGridList(
      minItemWidth: 270,
      horizontalGridMargin: 20,
      horizontalGridSpacing: 30,
      verticalGridSpacing: 30,
      verticalGridMargin: 20,
      children: subjectList,
    );
  }
}
