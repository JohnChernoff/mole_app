import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

class LichessLogin {

  String codeVerifier = "";
  final String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final String host = "lichess.org";
  final String clientId = "molechess.com";
  final String redirectEndpoint = "http://127.0.0.1:555/";

  LichessLogin(login) {
    requestCode(login);
  }

  requestCode(login) async {
    codeVerifier = _createCodeVerifier();
    final grant = oauth2.AuthorizationCodeGrant(
        clientId,
        Uri.parse("$host/oauth"),
        Uri.parse("$host/api/token"),
        httpClient: http.Client(),
        codeVerifier: codeVerifier);

    final authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectEndpoint), scopes: []);
    await _openAuthorizationServerLogin(authorizationUrl);

    var server = await HttpServer.bind("127.0.0.1", 555);
    await server.forEach((HttpRequest request) {
      final params =  request.uri.queryParameters;
      getTokenAndLogin(params["code"]!,login);
      request.response.close();
      server.close();
    });
  }

  getTokenAndLogin(String code,login) async {
    final tokenParameters = {
      "code_verifier": codeVerifier,
      "grant_type": "authorization_code",
      "code": code,
      "redirect_uri": redirectEndpoint,
      "client_id": clientId
    };

    http.post(
      Uri.parse('https://$host/api/token'),
      body: tokenParameters,
    ).then((response) { //print(response.body);
      login(jsonDecode(response.body)["access_token"]);
    });
  }

  Future<void> _openAuthorizationServerLogin(Uri authUri) async {
    var authUriString = 'https://${authUri.toString()}';
    if (await canLaunchUrl(Uri.parse(authUriString))) {
      await launchUrl(Uri.parse(authUriString), webOnlyWindowName: '_self');
    } else {
      throw 'Could not launch $authUri';
    }
  }

  String _createCodeVerifier() {
    return List.generate(
        128, (i) => _charset[Random.secure().nextInt(_charset.length)]).join();
  }

}