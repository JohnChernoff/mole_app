import 'package:flutter/material.dart';
import 'mole_client.dart';

class OptionsPage extends StatelessWidget {

  final MoleClient client;
  const OptionsPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
      return Column(
        children: [
          IconButton(
            onPressed: client.logoutFromLichess,
            icon: const Icon(Icons.delete),
          ),
        ],
      );
  }

}