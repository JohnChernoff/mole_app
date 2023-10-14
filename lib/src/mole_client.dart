import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mole_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';
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
  List<dynamic> chat = [];
  MoleGame(this.title);
}

class MoleClient extends ChangeNotifier implements MoleListener {
  static const String dummyTitle= "?";
  ChessBoardController controller = ChessBoardController();
  bool orientWhite = true;
  int counter = 0;
  Map<String,MoleGame> games = {};
  MoleGame currentGame = MoleGame(dummyTitle);
  String lichessToken = "";
  SharedPreferences? prefs;
  String userName = "";
  Map<String,Function> functionMap = {};
  bool confirmAI = false;
  late MoleSock sock;

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
      "game_update" : handleGameUpdate,
      "status" : handleStatus,
      "serv_msg" : handleGameMsg,
      "game_msg" : handleGameMsg,
      "chat" : handleChat
    };
  }

  void switchGame(String title) {
    currentGame = games[title]!;
    controller.loadFen(currentGame.fen);
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
    currentGame.fen = controller.getFen();
  }

  void handleMove() {
    print(controller.game.history.last.move.fromAlgebraic);
    print(controller.game.history.last.move.toAlgebraic);
    print(controller.game.history.last.move.promotion);
    controller.loadFen(currentGame.fen);
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

  void handleStatus(data) async {
    BuildContext? ctx = globalNavigatorKey.currentContext; if (ctx == null) return;
    String msg = data["msg"];
    if (msg == "ready") {
      gameCmd("startGame");
    } else if (msg == "insufficient") {
      if (await showDialog(
          context: ctx,
          builder: (BuildContext context) {
            return const Center(child: ConfirmDialog("Add AI?"));
          })) {
        gameCmd("startgame");
      }
    }
  }

  void handleChat(data) {
    if (data["source"] == "serv") {
      data["msg"] = "${data["user"]}: ${data["msg"]}";
    }
    else {
      data["msg"] = "${data["player"]?["user"]?["name"]}: ${data["msg"]}";
    }
    handleGameMsg(data);
  }

  void handleGameMsg(data) {
    print("Game Message: ${data["msg"]}");
    final title = data["source"]; if (title == null) return;
    MoleGame? game = games[title]; if (game == null) return;
    game.chat.add({
      "msg": data["msg"],
      "player": data["player"]?["user"]?["name"] ?? "serv",
      "color": data["player"]?["play_col"] ?? "#FFFFFF"
    });

  }

  void gameCmd(String cmd) {
    send(cmd,data: currentGame.title);
  }

  void handleGamesUpdate(json) {
    print("Games update:");
    for (var game in json) {
        String title = game["title"];
        print(title);
        games.putIfAbsent(title, () {
          MoleGame moleGame = MoleGame(title);
          if (currentGame.title == dummyTitle) currentGame = moleGame;
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
    if (currentFEN != null) {
      game.fen = currentFEN;
      if (currentGame == game) controller.loadFen(game.fen);
    }
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

  void startCurrentGame() {
    send("status",data: currentGame.title);
  }

  void sendChat(String msg) {
    send("chat",data: { "msg": msg, "source": currentGame.title });
  }

  @override
  void handleMsg(String msg) { //print("Incoming msg: $msg");
    final json = jsonDecode(msg);
    String type = json["type"];
    //print("Handling: $type");
    Function? fun = functionMap[type];
    if (fun != null) {
      fun(json["data"]);
    } else {
      //print("Function not found");
    }
    notifyListeners();
      if (type == "chat" || type == "serv_msg" || type == "game_msg") {
      if (ChatPage.scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 500), () {
          ChatPage.scrollController.animateTo(
            ChatPage.scrollController.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        });
      }
    }
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

class ConfirmDialog extends StatelessWidget {
  final String txt; //final Function onOK;
  const ConfirmDialog(this.txt, {super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Text(txt),
        SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context,true);
            },
            child: const Text('OK')),
        SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context,false);
            },
            child: const Text('Cancel')),
      ],
    );
  }
}



