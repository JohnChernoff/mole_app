import 'package:flutter/material.dart';
import 'package:mole_app/src/mole_client.dart';

class TopPage extends StatelessWidget {
  final MoleClient client;

  const TopPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: client.waitMap["top"] ?? false
                ? const Text("Getting top players...")
                : ListView(
                    children: List.generate(client.topPlayers.length,
                        (index) => Text(client.topPlayers[index].toString())),
                  )),
      ],
    );
  }
}
