import 'package:flutter/material.dart';

import 'mole_client.dart';

class LoginPage extends StatelessWidget {

  MoleClient client;
  LoginPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
          children: [
            ElevatedButton(
              onPressed: client.lichessToken == "" ? client.loginWithLichess : client.logoutFromLichess,
              child: client.lichessToken == "" ? const Text("Login with Lichess") : const Text("Logout"),
            ),
          ]
      ),
    );
  }
}