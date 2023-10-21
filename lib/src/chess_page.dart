import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'mole_client.dart';
import 'package:flutter/material.dart';

class ChessPage extends StatelessWidget {

  final MoleClient client;
  static bool history = false;

  const ChessPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              //homePage.setPage(Pages.history);
              history = true;
              client.notifyListeners();
              },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.history),
                Text(" History"),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () { client.send("resign",data: client.currentGame.title); },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.transit_enterexit),
                    Text(" Resign"),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () { client.send("veto",data: { "game": client.currentGame.title, "confirm" : true}); },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.cancel),
                    Text(" Veto"),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () { client.send("inspect",data: client.currentGame.title); },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.find_replace),
                    Text(" Inspect"),
                  ],
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () { client.flipBoard(); },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.invert_colors),
                Text(" Flip"),
              ],
            ),
          ),
          ChessBoard(
            onMove: client.sendMove,
            size: double.tryParse(MainAxisSize.max.toString()),
            controller: client.mainBoardController,
            boardColor: BoardColor.green,
            boardOrientation: client.orientWhite
                ? PlayerColor.white
                : PlayerColor.black,
          ),
          Container(
            color: client.currentGame.jsonData?["turn"] == 0
                ? Colors.black //Color.lerp(Colors.white, Colors.black, client.getCountPercentage())
                : Colors.white, //Color.lerp(Colors.black, Colors.white, client.getCountPercentage()),
            height: 100,
            width: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  strokeAlign: -1,
                  strokeWidth: 16,
                  backgroundColor: Colors.red,
                  color: Colors.green,
                  value: client.getCountPercentage(),
                  semanticsLabel: 'Circular progress indicator',
                ),
                Center(
                    child: Text(
                  "${client.currentGame.countdown["currentTime"].floor()}",
                  //${client.turnString()}:
                  style: TextStyle(
                    fontSize: client.currentGame.countdown["currentTime"] > 99
                        ? 24
                        : 42,
                    color: client.currentGame.jsonData?["turn"] == 0
                        ? Colors
                            .white //Color.lerp(Colors.white, Colors.black, client.getCountPercentage())
                        : Colors
                            .black, //Color.lerp(Colors.black, Colors.white, client.getCountPercentage()),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}