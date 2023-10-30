import 'package:chessground/chessground.dart';
import 'mole_client.dart';
import 'package:flutter/material.dart';

class ChessPage extends StatelessWidget {

  final MoleClient client;
  static bool history = false;

  const ChessPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: () { //homePage.setPage(Pages.history);
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
          Board(
            settings: const BoardSettings(
              pieceAssets: PieceSet.californiaAssets,
              colorScheme: BoardColorScheme.horsey
            ),
            size: screenWidth,
            data: BoardData(
              sideToMove: client.currentGame.sideToMove() == SideToMove.white ? Side.white : Side.black,
              interactableSide: client.currentGame.sideToMove() == SideToMove.white ? InteractableSide.white : InteractableSide.black,
              orientation: client.orientWhite ? Side.white : Side.black,
              fen: client.currentGame.fen,
              validMoves: client.getLegalMoves(),
            ),
            onMove: client.sendMove,
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                CustomPaint(
                  painter: ClockPainter(client.currentGame.jsonData?["turn"] == 0 ? Colors.black : Colors.white),
                ),
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
                  "${client.currentGame.countdown["currentTime"].floor()}", //${client.turnString()}:
                  style: TextStyle(
                    fontSize: client.currentGame.countdown["currentTime"] > 99
                        ? 24
                        : 42,
                    color: client.currentGame.jsonData?["turn"] == 0 ? Colors.white : Colors.black,
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

class ClockPainter extends CustomPainter {

  final Paint p = Paint();
  ClockPainter(Color color) {
    p.color = color;
    p.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) { //print("Size: $size");
      canvas.drawCircle(Offset(size.width/2,size.width/2), size.shortestSide/2, p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
