import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:webview_flutter/webview_flutter.dart';

class LichessOauth {

  static WebViewController webViewController = WebViewController();
  static String codeVerifier = "";
  static String localhost = "10.0.2.2";  //final String localhost = "127.0.0.1";
  static const String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  static String host = "lichess.org";
  static String clientId = "molechess.com";
  static String redirectEndpoint = "http://0.0.0.0:8888/";

  static getToken(onToken) {
    _requestCode(onToken);
  }

  static _requestCode(onToken) async {
    codeVerifier = _createCodeVerifier();
    final grant = oauth2.AuthorizationCodeGrant(
        clientId,
        Uri.parse("$host/oauth"),
        Uri.parse("$host/api/token"),
        httpClient: http.Client(),
        codeVerifier: codeVerifier);

    final authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectEndpoint), scopes: []);
    await _openAuthorizationServerLogin(authorizationUrl);

    var server = await HttpServer.bind("0.0.0.0",8888); //localhost, 80);
    await server.forEach((HttpRequest request) {
      final params =  request.uri.queryParameters;
      _getTokenAndLogin(params["code"]!,onToken);
      request.response.close();
      server.close();
    });
  }

  static _getTokenAndLogin(String code,onToken) async {
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
      onToken(jsonDecode(response.body)["access_token"]);
    });
    closeInAppWebView();
  }

  static Future<void> _openAuthorizationServerLogin(Uri authUri) async {
    var authUriString = 'https://${authUri.toString()}';
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webViewController.loadRequest(Uri.parse(authUriString));
  }

  static String _createCodeVerifier() {
    return List.generate(
        128, (i) => _charset[Random.secure().nextInt(_charset.length)]).join();
  }

  static void deleteToken(token) {
    final headers = {
      "Authorization": "Bearer $token",
    };
    Uri uri = Uri.parse('https://$host/api/token');
    http.delete(uri,
    headers: headers).then((value) {
        print(value.body);
    });
  }

}
