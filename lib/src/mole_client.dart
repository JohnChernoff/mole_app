import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide Move;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:mole_app/main.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lichess_login.dart';
import 'mole_sock.dart';

const initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
enum SideToMove { white, black, none}

class MoleGame {
  final String title;
  String fen = initialFen;
  dynamic countdown = {
    "time": 0.0,
    "currentTime": 0.0
  };
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  dynamic jsonData;
  bool exists = true;
  MoleGame(this.title);

  SideToMove sideToMove() {
    return fen.split(" ")[1] == "w" ? SideToMove.white : SideToMove.black;
  }
}

class MoleClient extends ChangeNotifier {
  static const String dummyTitle= "?";
  MoleGame currentGame = MoleGame(dummyTitle);
  bool orientWhite = true;
  Map<String,MoleGame> games = {};
  String lichessToken = "";
  SharedPreferences? prefs;
  String userName = "";
  Map<String,Function> functionMap = {};
  bool confirmAI = false;
  bool isConnected = false;
  bool isLoggedIn = false;
  String address;
  late MoleSock sock;
  int lastUpdate = 0;
  bool starting = true;
  Map<String, dynamic> options = {};

  MoleClient(this.address) {
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
      "err_msg" : handleChat,
      "phase" : handlePhase,
      "no_log" : loggedOut,
      "join" : handleJoin,
      "role" : handleRole,
      "defection" : handleDefection,
      "rampage" : handleRampage,
      "molebomb" : handleMolebomb,
      "options" : handleOptions
    };
    _connect();
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

  void submitOptions() {
    print(jsonEncode(options));
    send("set_opt",data: options);
  }

  void handleOptions(data) {
      options = data;
      options.putIfAbsent("game", () => currentGame.title);
  }

  //TODO: fix server to work with these
  void handleDefection(data) {
    if (getGame(data["source"]) == currentGame) {
      popup("${data["player"]["user"]["name"]} defects!",
          imgFilename: "defection.png");
    }
  }

  void handleRampage(data) {
    if (getGame(data["source"]) == currentGame) {
      popup("${data["player"]["user"]["name"]} rampages!",
          imgFilename: "rampage.png");
    }
  }

  void handleMolebomb(data) {
    if (getGame(data["source"]) == currentGame) {
      popup("${data["player"]["user"]["name"]} bombs!",
          imgFilename: "molebomb.png");
    }
  }

  void handleRole(data) {
    MoleGame game = getGame(data["source"]);
    if (game == currentGame) {
      String role = data["msg"];
      popup("You are the $role",imgFilename: "${role.toLowerCase()}.png");
    }
  }

  void handleJoin(data) { //print("Joining");
    handleGameUpdate(data);
    switchGame(data["title"]);
  }

  void handlePhase(data) { //print(data["phase"]);
    handleGameUpdate(data);
  }

  void handleMove(data) { //print("New move: ${data['move']}");
    final title = data["title"]; //print("Updating: $title");
    final MoleGame game = getGame(title);
    _updateMoveHistory(data,game);
  }

  void sendMove(Move move, {bool? isDrop, bool? isPremove}) {
    //print("Sending move: ${move.from}${move.to}");
    final prom = move.promotion.toString(); //print(prom);
    send("move",data: {
      "move" : "${move.from}${move.to}",
      "game" : currentGame.title,
      "promotion" : prom == "null" ? null : prom
    });
  }

  IMap<String, ISet<String>> getLegalMoves() {
    return algebraicLegalMoves(Chess.fromSetup(Setup.parseFen(currentGame.fen)));
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
      popup("Add AI?").then((ok)  { //print("OK: $ok");
        if (ok) gameCmd("startgame");
      });
    }
  }

  void handleChat(data) {
    if (data["source"] == "serv") {
      data["msg"] = "${data["user"] ?? "Serv"}: ${data["msg"]}";
    }
    else {
      data["msg"] = "${data["player"]?["user"]?["name"] ?? "WTF"}: ${data["msg"]}";
    }
    handleGameMsg(data);
  }

  void handleGameMsg(data) {  //print("Game Message: ${data["msg"]}");
    MoleGame? game = games[data["source"]];
    if (game == null) { //server message
      popup(data["msg"]);
    }
    else {
      game.chat.add({
        "msg": data["msg"],
        "player": data["player"]?["user"]?["name"] ?? "serv",
        "color": data["player"]?["play_col"] ?? "#FFFFFF"
      });
    }
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
    final currentFEN = json["currentFEN"]; //print("Current FEN: $currentFEN");
    final time = double.tryParse(json["timeRemaining"].toString());
    final history = json["history"];
    if (currentFEN != null) {
      game.fen = currentFEN;
      //if (currentGame == game) mainBoardController.loadFen(game.fen);
    }
    if (time != null && time > 0) _countdown(time,game);
    if (history != null) _updateMoveHistory(json,game);
    game.jsonData = json;
  }

  void _countdown(double time, MoleGame game) { //print("Countdown: $time");
    if (time > game.countdown["currentTime"]) {
      game.countdown["time"] = time;
    }
    game.countdown["currentTime"] = time;
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
      lastUpdate = DateTime.timestamp().millisecondsSinceEpoch;
    }
    else if (data["move_votes"] != null) {
      if (game.moves.length + 1 == data["ply"]) {
        //print("Adding to movelist: ${data["move"]}");
        game.moves.add(data["move_votes"]);
      }
      else if ((DateTime.timestamp().millisecondsSinceEpoch - lastUpdate) > 5000) {
        print("Inconsistent move history, updating...");
        send("update",data:game.title);
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
    if (!starting && lichessToken != "") {
      _login();
    } //else notify user somehow?
  }

  void disconnected() {
    isConnected = false; isLoggedIn = false;
    print("Disconnected: $userName");
    popup("Disconnected!  Log back in?").then((ok) {
      if (ok) _connect();
    });
  }

  void loggedIn(data) {
    userName = data["name"]; print("Logged in: $userName");
    isLoggedIn = true;
    starting = false;
  }

  void loggedOut(data) {
    print("Logged out: $userName");
    isLoggedIn = false;
    popup("Logged out!  Log back in?").then((ok) {
      if (ok) _login();
    });
  }

  Future<bool> popup (String txt, { String? imgFilename }) async {
    BuildContext? ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return false;
    return showDialog(
        context: ctx,
        builder: (BuildContext context) {
          return Center(
              child: imgFilename == null
                  ? ConfirmDialog(txt)
                  : NotificationDialog(txt, imgFilename));
        }).then((ok) => ok);
  }

}

class ConfirmDialog extends StatelessWidget {
  final String txt;
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

class NotificationDialog extends StatelessWidget {
  final String txt;
  final String imageFilename;
  const NotificationDialog(this.txt, this.imageFilename, {super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Text(txt),
        Image.asset("assets/images/$imageFilename"),
        SimpleDialogOption(
            onPressed: () { //print("True");
              Navigator.pop(context,true);
            },
            child: const Text('Continue')),
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