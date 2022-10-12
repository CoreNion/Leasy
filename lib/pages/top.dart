import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TopPage extends StatefulHookConsumerWidget {
  const TopPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopPageState();
}

class _TopPageState extends ConsumerState<TopPage> {
  @override
  Widget build(BuildContext context) {
    return const Text("top");
  }
}
