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
        Expanded(
          child: WebViewWidget(
            controller: LichessOauth.webViewController,
          ),
        ),
      ],
    );
  }

}