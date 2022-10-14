import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateSubjectPage extends StatefulHookConsumerWidget {
  const CreateSubjectPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateSubjectStatePage();
}

class _CreateSubjectStatePage extends ConsumerState<CreateSubjectPage> {
  @override
  Widget build(BuildContext context) {
    return const Text("Create");
  }
}
