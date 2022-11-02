import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubjectOverview extends StatefulHookConsumerWidget {
  final String title;
  const SubjectOverview({required this.title, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SubjectOverviewState();
}

class _SubjectOverviewState extends ConsumerState<SubjectOverview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title)));
  }
}
