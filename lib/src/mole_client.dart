import 'dart:convert';
import 'dart:math';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:mole_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lichess_login.dart';
import 'mole_sock.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;

class MoleGame {
  final String title;
  String fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  dynamic countdown = {
    "time": 0.0,
    "currentTime": 0.0
  };
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  dynamic jsonData;
  bool exists = true;
  MoleGame(this.title);
}

class MoleClient extends ChangeNotifier {
  static const String dummyTitle= "?";
  MoleGame currentGame = MoleGame(dummyTitle);
  ChessBoardController mainBoardController = ChessBoardController();
  ChessBoardController historyBoardController = ChessBoardController();
  CountDownController countDownController = CountDownController();
  bool orientWhite = true;
  Map<String,MoleGame> games = {};
  String lichessToken = "";
  SharedPreferences? prefs;
  String userName = "";
  Map<String,Function> functionMap = {};
  bool confirmAI = false;
  late MoleSock sock;
  bool isConnected = false;
  bool isLoggedIn = false;
  String address;
  dynamic homePage;

  MoleClient(this.address) {
    //fen = controller.getFen(); //controller.addListener(() {});
    SharedPreferences.getInstance().then((sp) {
        prefs = sp;
        lichessToken = prefs?.getString('token') ?? "";
    });
    functionMap = {
      "log_OK" : loggedIn,
      "games_update" : handleGamesUpdate,
      "game_update" : handleGameUpdate,
      "move" : handleMove,
      "status" : handleStatus,
      "serv_msg" : handleGameMsg,
      "game_msg" : handleGameMsg,
      "chat" : handleChat,
      "phase" : handlePhase,
      "no_log" : loggedOut,
      "join" : handleJoin
    };
    _connect();
  }

  void setHomePage(dynamic page) {
    homePage = page;
  }

  void _connect() {
    print("Connecting to $address");
    sock = MoleSock(address,connected,handleMsg,disconnected);
  }

  void switchGame(String title) {
    if (games[title ?? ""] != null) {
      currentGame = games[title]!;
      send("update",data:title);
    }
  }

  void handleJoin(data) {
    print("Joining");
    handleGameUpdate(data);
    switchGame(data["title"]);
  }

  void handlePhase(data) {
    print(data["phase"]);
    handleGameUpdate(data);
  }

  void handleMove(data) { //print("New move: ${data['move']}");
    final title = data["title"]; //print("Updating: $title");
    final MoleGame game = getGame(title);
    _updateMoveHistory(data,game);
  }

  void sendMove() {
    String move = mainBoardController.game.history.last.move.fromAlgebraic + mainBoardController.game.history.last.move.toAlgebraic;
    String prom =  mainBoardController.game.history.last.move.promotion?.toString() ?? "";
    mainBoardController.loadFen(currentGame.fen);
    print("Sending: ${move + prom}"); //print(controller.game.history.last.move.promotion);
    send("move",data: {
      "move" : move,
      "game" : currentGame.title,
      "promotion" : prom
    });
  }

  String turnString() {
    return currentGame.jsonData?["turn"] == 0 ? "Black" : "White";
  }

  void flipBoard() {
    orientWhite = !orientWhite;
    notifyListeners();
  }

  void send(String type, { var data = "" }) {
    sock.send(jsonEncode( { "type": type, "data": data } ) );
  }

  void logoutFromLichess() {
    if (lichessToken != "") {
      LichessOauth.deleteToken(lichessToken);
      prefs?.remove("token"); lichessToken = "";
    }
  }

  void loginWithLichess() {
    if (lichessToken == "") {
      LichessOauth.getToken((String tok) {
        lichessToken = tok;
        prefs?.setString("token",lichessToken);
        _login();
      });
    }
    else { _login(); }
  }

  void _login() {
    homePage.selectedPage = Pages.lobby;
    print("Logging in with token");
    send("login", data: lichessToken);
    notifyListeners();
  }

  void _logout() {
    send("logout");
    notifyListeners();
  }

  void handleStatus(data) async {
    String msg = data["msg"];
    if (msg == "ready") {
      gameCmd("startGame");
    } else if (msg == "insufficient") {
      ask("Add AI?").then((ok)  { //print("OK: $ok");
        if (ok) gameCmd("startgame");
      });
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

  void handleGameMsg(data) {  //print("Game Message: ${data["msg"]}");
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

  void handleGamesUpdate(json) { //print("Games update: $json");
    for (MoleGame game in games.values) {
      game.exists = false;
    }
    for (var game in json) {
      getGame(game["title"]).exists = true;
    }
    games.removeWhere((key, value) => !value.exists);
    if (currentGame.title == dummyTitle && games.keys.isNotEmpty) {
      switchGame(games.keys.first);
    }
  }

  MoleGame getGame(String title) {
    return games.putIfAbsent(title, () {
      //MoleGame moleGame = ;
      //if (currentGame.title == dummyTitle) currentGame = moleGame;
      return MoleGame(title);
    });
  }

  //called in the event of a new phase or in response to an update request
  void handleGameUpdate(json) {
    final title = json["title"]; //print("Updating: $title");
    final MoleGame game = getGame(title);
    final currentFEN = json["currentFEN"]; print("Current FEN: $currentFEN");
    final time = double.tryParse(json["timeRemaining"].toString());
    final history = json["history"];
    if (currentFEN != null) {
      game.fen = currentFEN;
      if (currentGame == game) mainBoardController.loadFen(game.fen);
    }
    if (time != null && time > 0) _countdown(time,game);
    if (history != null) _updateMoveHistory(json,game);
    game.jsonData = json;
  }

  void _countdown(double time, MoleGame game) {
    print("Countdown: $time");
    if (time > game.countdown["currentTime"]) {
      game.countdown["time"] = time;
    }
    game.countdown["currentTime"] = time;
    //countDownController.start();
  }

  double getCountPercentage() {
    double p = (currentGame.countdown["currentTime"]/currentGame.countdown["time"]);
    if (p.isFinite) {
      return p;
    } else {
      return 0;
    }
  }

  void _updateMoveHistory(data, MoleGame game) {
    if (data["history"] != null) {
      print("Updating history: ${game.title}");
      game.moves.clear();
      for (var votes in data["history"]) {
        game.moves.add(votes);
      }
    }
    else if (data["move_votes"] != null) {
      if (game.moves.length + 1 == data["ply"]) {
        print("Adding to movelist: ${data["move"]}");
        game.moves.add(data["move_votes"]);
      }
    }
  }

  void newGame(String title) { //print("Create game: $title");
    send("newgame",data :{"game": title, "color": 0});
  }

  void startCurrentGame() {
    send("status",data: currentGame.title);
  }

  void leaveCurrentGame() {
    send("partGame",data: currentGame.title);
  }

  void sendChat(String msg) {
    send("chat",data: { "msg": msg, "source": currentGame.title });
  }

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
    }
  }

  void connected() {
    print("Connected!");
    isConnected = true;
    //loginWithLichess(); //if (lichessToken != "") _login();
  }

  void disconnected() {
    isConnected = false; isLoggedIn = false;
    print("Disconnected: $userName");
    ask("Disconnected!  Log back in?").then((ok) {
      if (ok) _connect();
    });
  }

  void loggedIn(data) {
    userName = data["name"]; print("Logged in: $userName");
    isLoggedIn = true;
  }

  void loggedOut() {
    print("Logged out: $userName");
    isLoggedIn = false;
    ask("Logged out!  Log back in?").then((ok) {
      _login();
    });
  }

  Future<bool> ask (String question) async {
    BuildContext? ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return false;
    return showDialog(
        context: ctx,
        builder: (BuildContext context) {
          return Center(child: ConfirmDialog(question));
        }).then((ok) => ok);
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
            onPressed: () { //print("True");
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

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Color rndColor() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}