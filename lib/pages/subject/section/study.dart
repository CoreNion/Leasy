import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SectionStudyPage extends StatefulHookConsumerWidget {
  final int sectionID;
  final String sectionTitle;

  const SectionStudyPage({
    super.key,
    required this.sectionID,
    required this.sectionTitle,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SectionStudyPageState();
}

class _SectionStudyPageState extends ConsumerState<SectionStudyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
      ),
      body: Text(widget.sectionID.toString()),
    );
  }
}
