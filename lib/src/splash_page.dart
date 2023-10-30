import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'lichess_login.dart';
import 'mole_client.dart';

class SplashPage extends StatelessWidget {

  final MoleClient client;
  const SplashPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () { client.loginWithLichess(); },
            child: const Text("Login with Lichess")),
        client.lichessToken == ""
            ? Expanded(
                child: WebViewWidget(
                  controller: LichessOauth.webViewController,
                ),
              )
            : Image.asset(
                "assets/images/mole_splash.png",
                //"assets/images/mole_spin.gif",
                width: 1000,
                height: 580,
              ),
      ],
    );
  }

}