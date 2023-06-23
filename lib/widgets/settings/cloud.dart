import 'package:flutter/material.dart';

import '../../class/cloud.dart';

class CheckCurrentStatus extends StatefulWidget {
  const CheckCurrentStatus({super.key, required this.accountInfo});

  final CloudAccountInfo accountInfo;

  @override
  State<CheckCurrentStatus> createState() => _CheckCurrentStatusState();
}

class _CheckCurrentStatusState extends State<CheckCurrentStatus> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final boxDeco = BoxDecoration(
        color: colorScheme.background,
        border: Border.all(color: colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(10)));

    return Container(
        padding: const EdgeInsets.all(5),
        decoration: boxDeco,
        child: Column(
          children: [
            const Text("同期状況", style: TextStyle(fontSize: 20)),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Icon(
                  widget.accountInfo.type == CloudType.none
                      ? Icons.cloud_off
                      : Icons.cloud_done,
                  color: colorScheme.primary,
                  size: 40),
              Text(widget.accountInfo.type.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
            ]),
            Text(widget.accountInfo.email ?? "",
                style: const TextStyle(fontSize: 15)),
          ],
        ));
  }
}
