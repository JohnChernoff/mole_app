import 'package:chessground/chessground.dart';
import 'game_history_page.dart';
import 'mole_client.dart';
import 'package:flutter/material.dart';

enum ChessPages { currentBoard,historyBoard }

class ChessPage extends StatefulWidget {
  final MoleClient client;
  const ChessPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _ChessPage();

}

class _ChessPage extends State<ChessPage> {
  ChessPages page = ChessPages.currentBoard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (page == ChessPages.historyBoard) {
                    page = ChessPages.currentBoard;
                  } else {
                    page = ChessPages.historyBoard;
                  }
                });
              },
              icon: page == ChessPages.historyBoard ? const Icon(Icons.arrow_back) : const Icon(Icons.history),
            ),
            IconButton(
              onPressed: () { widget.client.flipBoard(); },
              icon: const Icon(Icons.invert_colors)
            ),
          ],
        ),
        Expanded(
          flex: page == ChessPages.currentBoard ? 0 : 1,
            child: switch (page) {
          ChessPages.currentBoard => CurrentBoardPage(widget.client),
          ChessPages.historyBoard => GameHistoryPage(widget.client),
        }),
      ],
    );
  }
}

class CurrentBoardPage extends StatelessWidget {
  final MoleClient client;
  const CurrentBoardPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
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
          SizedBox(width: screenWidth, height: 8),
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
          SizedBox(width: screenWidth, height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
              Container(
                //color: Colors.brown,
                height: 100,
                width: (screenWidth-100)/2,
                child: ListView(
                    scrollDirection: Axis.vertical,
                    children: List.generate(
                        client.currentGame.currentVotes.length, (index) {
                      return Text(
                        "${client.currentGame.currentVotes[index]["player_name"]}: ${client.currentGame.currentVotes[index]["player_move"]}",
                        style: const TextStyle(
                          //color: Colors.amberAccent
                        ),
                      );
                    })),
              ),
            ],
          ),
        ],
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
