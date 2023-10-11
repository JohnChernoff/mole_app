import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lichess_login.dart';
import 'mole_sock.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

abstract class MoleListener {
  void handleMsg(String msg);
  void loggedIn(String token);
  void connected();
  void disconnected();
}

class MoleClient extends ChangeNotifier implements MoleListener {
  late MoleSock sock;
  late String fen;
  ChessBoardController controller = ChessBoardController();
  bool orientWhite = true;
  int counter = 0;
  String lichessToken = "";
  SharedPreferences? prefs;
  String userName = "";
  late Map<String,Function> functionMap;

  MoleClient(address) {
    fen = controller.getFen(); //controller.addListener(() {});
    SharedPreferences.getInstance().then((sp) {
        prefs = sp;
        lichessToken = prefs?.getString('token') ?? "";
        print("Connecting to $address");
        sock = MoleSock(address,connected,handleMsg);
    });
    functionMap = {
      "log_OK" : handleLogin,
      "games_update" : handleGameUpdate
    };
  }

  void rndMove() {
    counter++;
    List<Move> moves = controller.getPossibleMoves();
    var move =
        controller.getPossibleMoves().elementAt(Random().nextInt(moves.length));
    final promotion = move.promotion;
    if (promotion != null) {
      controller.makeMoveWithPromotion(
          from: move.fromAlgebraic,
          to: move.toAlgebraic,
          pieceToPromoteTo: promotion.name);
    } else {
      controller.makeMove(from: move.fromAlgebraic, to: move.toAlgebraic);
    }
    fen = controller.getFen();
  }

  void handleMove() {
    print(controller.game.history.last.move.fromAlgebraic);
    print(controller.game.history.last.move.toAlgebraic);
    print(controller.game.history.last.move.promotion);
    controller.loadFen(fen);
  }

  void flipBoard() {
    orientWhite = !orientWhite;
  }

  void send(String type, { String data = "" }) {
    sock.send(jsonEncode( { "type": type, "data": data } ) );
  }

  void logoutFromLichess() {
    prefs?.remove("token"); lichessToken = ""; _logout();
  }

  void loginWithLichess() {
    if (lichessToken == "") {
      LichessLogin((String tok) {
        lichessToken = tok;
        prefs?.setString("token",lichessToken);
        _login();
      });
    }
    else { _login(); }
  }

  void _login() {
    send("login", data: lichessToken);
    notifyListeners();
  }

  void _logout() {
    send("logout");
    notifyListeners();
  }

  void handleLogin(data) {
    userName = data["name"];
    print("Logged in: $userName");
  }

  void handleGameUpdate(data) {
    print("Games update:");
    print(data);
  }

  @override
  void connected() {
    if (lichessToken != "") _login();
  }

  @override
  void disconnected() {
    // TODO: implement disconnected
  }

  @override
  void handleMsg(String msg) {
    final json = jsonDecode(msg);
    String type = json["type"]; print("Handling: $type");
    Function? fun = functionMap[type];
    if (fun != null) fun(json["data"]);
    else print("Fucntion not found");
    notifyListeners();
  }

  @override
  void loggedIn(String token) {

  }

}