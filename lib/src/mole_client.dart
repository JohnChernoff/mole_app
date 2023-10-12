import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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

class MoleGame {
  final String title;
  String fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  int time = 0;
  List<dynamic> moves = [];
  List<dynamic> teams = [];

  MoleGame(this.title);
}

class MoleClient extends ChangeNotifier implements MoleListener {
  late MoleSock sock;
  ChessBoardController controller = ChessBoardController();
  bool orientWhite = true;
  int counter = 0;
  Map<String,MoleGame> games = {};
  MoleGame? currentGame;
  String lichessToken = "";
  SharedPreferences? prefs;
  String userName = "";
  Map<String,Function> functionMap = {};
  bool confirmAdd = false;
  bool confirmName = false;

  MoleClient(address) {
    //fen = controller.getFen(); //controller.addListener(() {});
    SharedPreferences.getInstance().then((sp) {
        prefs = sp;
        lichessToken = prefs?.getString('token') ?? "";
        print("Connecting to $address");
        sock = MoleSock(address,connected,handleMsg);
    });
    functionMap = {
      "log_OK" : handleLogin,
      "games_update" : handleGamesUpdate,
      "game_update" : handleGameUpdate
    };
  }

  void switchGame(String title) {
    currentGame = games[title]!;
    notifyListeners();
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
    currentGame!.fen = controller.getFen();
  }

  void handleMove() {
    print(controller.game.history.last.move.fromAlgebraic);
    print(controller.game.history.last.move.toAlgebraic);
    print(controller.game.history.last.move.promotion);
    controller.loadFen(currentGame!.fen);
  }

  void flipBoard() {
    orientWhite = !orientWhite;
  }

  void send(String type, { var data = "" }) {
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

  void handleGamesUpdate(json) {
    print("Games update:");
    for (var game in json) {
        String title = game["title"];
        print(title);
        games.putIfAbsent(title, () {
          MoleGame moleGame = MoleGame(title);
          currentGame ??= moleGame;
          return moleGame;
        });
    }
  }

  void handleGameUpdate(json) {
    final title = json["title"];
    final MoleGame? game = games[title]; if (game == null) return;
    final currentFEN = json["currentFEN"];
    final time = json["timeRemaining"];
    final history = json["history"];

    if (currentFEN != null) game.fen = currentFEN;
    if (time != null && time > 0) _countdown(time,game);
    if (history != null) _updateMoveHistory(json,game);
    notifyListeners();
  }

  void _countdown(int time, MoleGame game) {
    game.time = time; //TODO: implement timer
  }

  void _updateMoveHistory(data, MoleGame game) {
    if (data["history"] != null) {
      for (var votes in data["history"]) {
        game.moves.clear();
        game.moves.add(votes);
      }
    }
    else if (data["move_votes"] != null) {
      game.moves.add(data["move_votes"]);
    }
  }

  void newGame(String title) {
    print("Create game: $title");
    send("newgame",data :{"game": title, "color": 0});
  }

  @override
  void handleMsg(String msg) { print("Incoming msg: $msg");
  final json = jsonDecode(msg);
  String type = json["type"]; print("Handling: $type");
  Function? fun = functionMap[type];
  if (fun != null) {
    fun(json["data"]);
  } else {
    print("Fucntion not found");
  }
  notifyListeners();
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
  void loggedIn(String token) {
  }

}